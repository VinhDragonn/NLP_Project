import os
from typing import List, Optional
from contextlib import asynccontextmanager

import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from imblearn.under_sampling import RandomUnderSampler

# ===== Config =====
CSV_PATH = os.getenv(
    "RT_CSV_PATH",
    "C:/Users/vinh0/Documents/aaaaaaaaaaaaaaaaaaaaaaaaaaa/rotten_tomatoes_movies.csv",
)
RANDOM_STATE = 42

def load_and_train():
    df = pd.read_csv(CSV_PATH)
    if "tomatometer_rating" not in df.columns:
        raise RuntimeError("CSV missing column 'tomatometer_rating'.")

    # Label
    df = df.dropna(subset=["tomatometer_rating"])
    df["success"] = (df["tomatometer_rating"] >= 70).astype(int)

    # Extract year
    df["release_year"] = pd.to_datetime(
        df["original_release_date"], errors="coerce"
    ).dt.year
    df["release_year"] = df["release_year"].fillna(df["release_year"].mean())
    
    # ===== FEATURE ENGINEERING =====
    
    # 1. Director reputation (số phim đã làm)
    director_counts = df['directors'].value_counts()
    df['director_experience'] = df['directors'].map(director_counts).fillna(1)
    
    # 2. Genre popularity (một số genre thành công hơn)
    genre_success_rate = df.groupby('genres')['success'].mean()
    df['genre_success_rate'] = df['genres'].map(genre_success_rate).fillna(0.5)
    
    # 3. Production company track record
    company_success_rate = df.groupby('production_company')['success'].mean()
    df['company_success_rate'] = df['production_company'].map(company_success_rate).fillna(0.5)
    
    # 4. Runtime category (phim quá ngắn/dài thường kém)
    df['runtime_category'] = pd.cut(df['runtime'].fillna(df['runtime'].mean()), 
                                     bins=[0, 90, 120, 150, 300],
                                     labels=['short', 'medium', 'long', 'very_long'])
    
    # 5. Release season (mùa ra mắt ảnh hưởng)
    df['release_month'] = pd.to_datetime(df['original_release_date'], errors='coerce').dt.month
    df['release_season'] = df['release_month'].fillna(6).apply(
        lambda x: 'summer' if x in [6,7,8] 
        else 'holiday' if x in [11,12] 
        else 'spring' if x in [3,4,5]
        else 'fall'
    )
    
    # 6. Is sequel/franchise (dựa vào title có số)
    df['is_sequel'] = df['movie_title'].fillna('').str.contains(r'\d|II|III|IV', regex=True).astype(int)
    
    # 7. Director-Genre combination (một số director giỏi genre cụ thể)
    df['director_genre'] = df['directors'].astype(str) + '_' + df['genres'].astype(str).str.split('|').str[0]

    # Features
    categorical_features = ["directors", "genres", "production_company", "runtime_category", "release_season", "director_genre"]
    numerical_features = [
        "runtime", "release_year", 
        "director_experience", "genre_success_rate", "company_success_rate",
        "is_sequel"
    ]
    features = categorical_features + numerical_features

    # Fillna
    fill_values = {
        "directors": "Unknown",
        "genres": "Unknown",
        "production_company": "Unknown",
        "runtime": df["runtime"].mean(),
        "runtime_category": "medium",
        "release_season": "summer",
        "director_genre": "Unknown_Unknown",
        "director_experience": 1,
        "genre_success_rate": 0.5,
        "company_success_rate": 0.5,
        "is_sequel": 0,
    }
    X = df[features].fillna(fill_values)
    y = df["success"]

    # Preprocessing
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), numerical_features),
            (
                "cat",
                OneHotEncoder(handle_unknown="ignore", sparse_output=False, max_categories=50),
                categorical_features,
            ),
        ]
    )

    # ===== GRADIENT BOOSTING (thường tốt hơn Random Forest) =====
    model = Pipeline(
        steps=[
            ("preprocess", preprocessor),
            (
                "clf",
                GradientBoostingClassifier(
                    n_estimators=300,
                    learning_rate=0.05,
                    max_depth=5,
                    min_samples_split=20,
                    subsample=0.8,
                    random_state=RANDOM_STATE,
                ),
            ),
        ]
    )

    # Balance data
    rus = RandomUnderSampler(random_state=RANDOM_STATE)
    X_bal, y_bal = rus.fit_resample(X, y)

    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X_bal, y_bal, test_size=0.2, random_state=RANDOM_STATE
    )

    model.fit(X_train, y_train)

    # Evaluation
    try:
        from sklearn.metrics import classification_report, confusion_matrix
        y_pred = model.predict(X_test)
        print("\n" + "="*50)
        print("IMPROVED MODEL - Classification Report:")
        print("="*50)
        print(classification_report(y_test, y_pred))
        print("\nConfusion Matrix:")
        print(confusion_matrix(y_test, y_pred))
        print("="*50 + "\n")
        
        print(f"Training set - Success: {sum(y_train)}, Fail: {len(y_train) - sum(y_train)}")
        print(f"Test predictions - Success: {sum(y_pred)}, Fail: {len(y_pred) - sum(y_pred)}")
    except Exception as e:
        print(f"Could not compute report: {e}")

    return model, features, fill_values


class MovieFeatures(BaseModel):
    movie_title: Optional[str] = Field(None, description="Optional title for reference")
    directors: str
    genres: str
    production_company: str
    runtime: float
    release_year: float


class PredictResponse(BaseModel):
    prediction: int
    label: str
    confidence: Optional[float] = None


MODEL = None
FEATURES: List[str] = []
FILL_VALUES = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    global MODEL, FEATURES, FILL_VALUES
    print(f"Loading data and training IMPROVED model from: {CSV_PATH}")
    MODEL, FEATURES, FILL_VALUES = load_and_train()
    print("IMPROVED Model ready.")
    yield


app = FastAPI(title="Movie Success Predictor (IMPROVED)", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "model": "improved"}


@app.post("/predict", response_model=PredictResponse)
def predict(payload: MovieFeatures):
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Model not ready")

    # Feature engineering cho input mới
    data = {
        'directors': payload.directors,
        'genres': payload.genres,
        'production_company': payload.production_company,
        'runtime': payload.runtime,
        'release_year': payload.release_year,
        'runtime_category': 'short' if payload.runtime < 90 else 'medium' if payload.runtime < 120 else 'long' if payload.runtime < 150 else 'very_long',
        'release_season': 'summer',  # default
        'director_genre': f"{payload.directors}_{payload.genres.split('|')[0] if '|' in payload.genres else payload.genres}",
        'director_experience': 5,  # default
        'genre_success_rate': 0.5,  # default
        'company_success_rate': 0.5,  # default
        'is_sequel': 1 if payload.movie_title and any(c.isdigit() for c in payload.movie_title) else 0,
    }
    
    df_in = pd.DataFrame([data])

    try:
        pred = int(MODEL.predict(df_in)[0])
        proba = MODEL.predict_proba(df_in)[0]
        confidence = float(max(proba))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Prediction error: {e}")

    return PredictResponse(
        prediction=pred, 
        label=("Success" if pred == 1 else "Fail"),
        confidence=confidence
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
