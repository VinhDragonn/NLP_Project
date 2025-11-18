import os
from typing import List, Optional
from contextlib import asynccontextmanager

import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
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

    # Label: Success nếu rating >= 70 (nghiêm ngặt hơn)
    df = df.dropna(subset=["tomatometer_rating"])
    df["success"] = (df["tomatometer_rating"] >= 70).astype(int)

    # Extract year
    df["release_year"] = pd.to_datetime(
        df["original_release_date"], errors="coerce"
    ).dt.year
    df["release_year"] = df["release_year"].fillna(df["release_year"].mean())

    # CHỈ DÙNG FEATURES CÓ TRƯỚC KHI PHIM RA MẮT
    categorical_features = ["directors", "genres", "production_company"]
    numerical_features = ["runtime", "release_year"]  # BỎ audience_rating, tomatometer_count, audience_count
    features = categorical_features + numerical_features

    # Fillna
    fill_values = {
        "directors": "Unknown",
        "genres": "Unknown",
        "production_company": "Unknown",
        "runtime": df["runtime"].mean(),
    }
    X = df[features].fillna(fill_values)
    y = df["success"]

    # Preprocessing
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), numerical_features),
            (
                "cat",
                OneHotEncoder(handle_unknown="ignore", sparse_output=False),
                categorical_features,
            ),
        ]
    )

    model = Pipeline(
        steps=[
            ("preprocess", preprocessor),
            (
                "clf",
                RandomForestClassifier(
                    n_estimators=200,  # Tăng số trees
                    max_depth=15,      # Giới hạn depth để tránh overfit
                    min_samples_split=10,
                    random_state=RANDOM_STATE,
                    class_weight="balanced"
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
        print("FIXED MODEL - Classification Report:")
        print("="*50)
        print(classification_report(y_test, y_pred))
        print("\nConfusion Matrix:")
        print(confusion_matrix(y_test, y_pred))
        print("="*50 + "\n")
        
        # Distribution check
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
    # BỎ audience_rating, tomatometer_count, audience_count


class PredictResponse(BaseModel):
    prediction: int
    label: str
    confidence: Optional[float] = None


MODEL = None
FEATURES: List[str] = []
FILL_VALUES = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    global MODEL, FEATURES, FILL_VALUES
    print(f"Loading data and training FIXED model from: {CSV_PATH}")
    MODEL, FEATURES, FILL_VALUES = load_and_train()
    print("FIXED Model ready.")
    yield
    # Shutdown (cleanup if needed)


app = FastAPI(title="Movie Success Predictor (FIXED)", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "model": "fixed"}


@app.post("/predict", response_model=PredictResponse)
def predict(payload: MovieFeatures):
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Model not ready")

    # To DataFrame with required columns
    data = {k: getattr(payload, k) for k in FEATURES}
    df_in = pd.DataFrame([data]).fillna(FILL_VALUES)

    try:
        pred = int(MODEL.predict(df_in)[0])
        # Get probability for confidence
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
