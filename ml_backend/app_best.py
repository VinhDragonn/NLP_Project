import os
from typing import List, Optional
from contextlib import asynccontextmanager

import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import (
    RandomForestClassifier,
    GradientBoostingClassifier,
    VotingClassifier
)
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from imblearn.under_sampling import RandomUnderSampler

# ===== Config =====
CSV_PATH = os.getenv(
    "RT_CSV_PATH",
    "C:/Users/vinh0/Documents/aaaaaaaaaaaaaaaaaaaaaaaaaaa/rotten_tomatoes_movies.csv",
)
RANDOM_STATE = 42

def engineer_features(df):
    """Advanced feature engineering - NO LEAKAGE"""

    # 1. Director reputation (chỉ dùng số lượng, KHÔNG dùng success rate)
    director_counts = df['directors'].value_counts()
    df['director_experience'] = df['directors'].map(director_counts).fillna(1)
    df['director_is_prolific'] = (df['director_experience'] >= 5).astype(int)
    df['director_is_veteran'] = (df['director_experience'] >= 10).astype(int)

    # 2. Genre analysis (KHÔNG dùng success rate từ data)
    # Extract primary genre
    df['primary_genre'] = df['genres'].fillna('Unknown').str.split('|').str[0]

    # Count genres (multi-genre films)
    df['genre_count'] = df['genres'].fillna('').str.count(r'\|') + 1
    df['is_multi_genre'] = (df['genre_count'] >= 3).astype(int)

    # Popular genres (based on domain knowledge, not data)
    popular_genres = ['Action', 'Comedy', 'Drama', 'Thriller', 'Adventure', 'Science Fiction']
    df['is_popular_genre'] = df['primary_genre'].isin(popular_genres).astype(int)

    # 3. Production company (chỉ dùng số lượng, KHÔNG dùng success rate)
    company_counts = df['production_company'].value_counts()
    df['company_experience'] = df['production_company'].map(company_counts).fillna(1)
    df['is_major_studio'] = (df['company_experience'] >= 20).astype(int)

    # Major studios (domain knowledge)
    major_studios = ['Warner Bros.', 'Universal Pictures', 'Paramount Pictures',
                     'Walt Disney Pictures', '20th Century Fox', 'Columbia Pictures',
                     'Marvel Studios', 'Pixar', 'DreamWorks']
    df['is_known_studio'] = df['production_company'].isin(major_studios).astype(int)

    # 4. Runtime features
    df['runtime_filled'] = df['runtime'].fillna(df['runtime'].median())
    df['runtime_category'] = pd.cut(
        df['runtime_filled'],
        bins=[0, 85, 105, 130, 300],
        labels=['very_short', 'short', 'medium', 'long']
    )
    df['is_optimal_runtime'] = ((df['runtime_filled'] >= 95) & (df['runtime_filled'] <= 125)).astype(int)

    # 5. Release timing
    df['release_date'] = pd.to_datetime(df['original_release_date'], errors='coerce')
    df['release_month'] = df['release_date'].dt.month.fillna(6)
    df['release_quarter'] = df['release_date'].dt.quarter.fillna(2)

    # Summer blockbuster season (May-Aug) and Holiday season (Nov-Dec)
    df['is_blockbuster_season'] = df['release_month'].isin([5,6,7,8]).astype(int)
    df['is_holiday_season'] = df['release_month'].isin([11,12]).astype(int)
    df['is_awards_season'] = df['release_month'].isin([10,11,12,1]).astype(int)

    # 6. Year trends (REMOVE bias về phim mới)
    df['release_year_filled'] = df['release_year'].fillna(df['release_year'].median())
    # BỎ years_since_2000 và is_recent vì gây bias
    # df['years_since_2000'] = df['release_year_filled'] - 2000
    # df['is_recent'] = (df['release_year_filled'] >= 2015).astype(int)

    # 7. Title analysis
    df['title_length'] = df['movie_title'].fillna('').str.len()
    df['is_sequel'] = df['movie_title'].fillna('').str.contains(
        r'\d|II|III|IV|Part|Chapter|Episode',
        case=False,
        regex=True
    ).astype(int)
    df['has_colon'] = df['movie_title'].fillna('').str.contains(':').astype(int)

    # 8. Interaction features
    df['director_genre_combo'] = df['directors'].astype(str) + '_' + df['primary_genre'].astype(str)
    df['company_genre_combo'] = df['production_company'].astype(str) + '_' + df['primary_genre'].astype(str)

    return df

def load_and_train():
    print("Loading data...")
    df = pd.read_csv(CSV_PATH)

    if "tomatometer_rating" not in df.columns:
        raise RuntimeError("CSV missing column 'tomatometer_rating'.")

    # Label (70% threshold)
    df = df.dropna(subset=["tomatometer_rating"])
    df["success"] = (df["tomatometer_rating"] >= 70).astype(int)

    print(f"Dataset size: {len(df)}")
    print(f"Success rate: {df['success'].mean():.2%}")

    # Extract year
    df["release_year"] = pd.to_datetime(
        df["original_release_date"], errors="coerce"
    ).dt.year

    # Feature engineering
    print("Engineering features...")
    df = engineer_features(df)

    # Select features
    categorical_features = [
        "directors", "primary_genre", "production_company",
        "runtime_category", "director_genre_combo"
    ]

    numerical_features = [
        "runtime_filled", "release_year_filled",
        "director_experience", "director_is_prolific", "director_is_veteran",
        "genre_count", "is_multi_genre", "is_popular_genre",
        "company_experience", "is_major_studio", "is_known_studio",
        "is_optimal_runtime", "is_blockbuster_season", "is_holiday_season",
        "is_awards_season", "is_sequel", "has_colon",
        "title_length", "release_quarter"
    ]

    features = categorical_features + numerical_features

    # Fillna
    fill_values = {
        "directors": "Unknown",
        "primary_genre": "Unknown",
        "production_company": "Unknown",
        "runtime_category": "medium",
        "director_genre_combo": "Unknown_Unknown",
        **{feat: 0 for feat in numerical_features}
    }

    X = df[features].fillna(fill_values)
    y = df["success"]

    # Preprocessing
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), numerical_features),
            (
                "cat",
                OneHotEncoder(handle_unknown="ignore", sparse_output=False, max_categories=100),
                categorical_features,
            ),
        ]
    )

    # ===== ENSEMBLE MODEL =====
    print("Building ensemble model...")

    # Model 1: Gradient Boosting (best for structured data)
    gb = GradientBoostingClassifier(
        n_estimators=400,
        learning_rate=0.05,
        max_depth=6,
        min_samples_split=20,
        min_samples_leaf=10,
        subsample=0.8,
        random_state=RANDOM_STATE,
    )

    # Model 2: Random Forest (good for feature interactions)
    rf = RandomForestClassifier(
        n_estimators=300,
        max_depth=12,
        min_samples_split=15,
        min_samples_leaf=5,
        max_features='sqrt',
        random_state=RANDOM_STATE,
        class_weight='balanced',
    )

    # Model 3: Logistic Regression (linear baseline)
    lr = LogisticRegression(
        C=0.5,
        max_iter=1000,
        random_state=RANDOM_STATE,
        class_weight='balanced'
    )

    # Voting ensemble (soft voting for probability averaging)
    ensemble = VotingClassifier(
        estimators=[
            ('gb', gb),
            ('rf', rf),
            ('lr', lr)
        ],
        voting='soft',
        weights=[2, 1.5, 1]  # GB gets more weight
    )

    model = Pipeline(
        steps=[
            ("preprocess", preprocessor),
            ("clf", ensemble)
        ]
    )

    # Balance data
    print("Balancing dataset...")
    rus = RandomUnderSampler(random_state=RANDOM_STATE)
    X_bal, y_bal = rus.fit_resample(X, y)

    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X_bal, y_bal, test_size=0.2, random_state=RANDOM_STATE, stratify=y_bal
    )

    # Train
    print("Training ensemble model...")
    model.fit(X_train, y_train)

    # Evaluation
    try:
        from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score

        y_pred = model.predict(X_test)
        y_proba = model.predict_proba(X_test)[:, 1]

        print("\n" + "="*60)
        print("BEST MODEL (ENSEMBLE) - Classification Report:")
        print("="*60)
        print(classification_report(y_test, y_pred, digits=3))
        print("\nConfusion Matrix:")
        cm = confusion_matrix(y_test, y_pred)
        print(cm)
        print(f"\nROC-AUC Score: {roc_auc_score(y_test, y_proba):.3f}")
        print("="*60 + "\n")

        # Distribution
        print(f"Training set - Success: {sum(y_train)} ({sum(y_train)/len(y_train):.1%}), Fail: {len(y_train) - sum(y_train)} ({(len(y_train) - sum(y_train))/len(y_train):.1%})")
        print(f"Test predictions - Success: {sum(y_pred)} ({sum(y_pred)/len(y_pred):.1%}), Fail: {len(y_pred) - sum(y_pred)} ({(len(y_pred) - sum(y_pred))/len(y_pred):.1%})")

        # Feature importance (from GB)
        print("\nTop 10 Most Important Features:")
        feature_names = (
            numerical_features +
            list(preprocessor.named_transformers_['cat'].get_feature_names_out(categorical_features))
        )
        importances = model.named_steps['clf'].estimators_[0].feature_importances_
        top_indices = np.argsort(importances)[-10:][::-1]
        for idx in top_indices:
            if idx < len(feature_names):
                print(f"  {feature_names[idx]}: {importances[idx]:.4f}")

    except Exception as e:
        print(f"Could not compute detailed metrics: {e}")

    return model, features, fill_values


class MovieFeatures(BaseModel):
    movie_title: Optional[str] = Field(None, description="Movie title")
    directors: str
    genres: str
    production_company: str
    runtime: float
    release_year: float


class PredictResponse(BaseModel):
    prediction: int
    label: str
    confidence: float
    success_probability: float


MODEL = None
FEATURES: List[str] = []
FILL_VALUES = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    global MODEL, FEATURES, FILL_VALUES
    print(f"\n{'='*60}")
    print("BEST MODEL - Loading and Training")
    print(f"{'='*60}\n")
    MODEL, FEATURES, FILL_VALUES = load_and_train()
    print("\n✅ BEST Model ready for predictions!\n")
    yield


app = FastAPI(title="Movie Success Predictor (BEST)", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "model": "best_ensemble"}


@app.post("/predict", response_model=PredictResponse)
def predict(payload: MovieFeatures):
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Model not ready")

    # Feature engineering for new input
    primary_genre = payload.genres.split('|')[0] if '|' in payload.genres else payload.genres
    runtime_filled = payload.runtime if payload.runtime > 0 else 105

    data = {
        'directors': payload.directors,
        'primary_genre': primary_genre,
        'production_company': payload.production_company,
        'runtime_category': 'very_short' if runtime_filled < 85 else 'short' if runtime_filled < 105 else 'medium' if runtime_filled < 130 else 'long',
        'director_genre_combo': f"{payload.directors}_{primary_genre}",
        'runtime_filled': runtime_filled,
        'release_year_filled': payload.release_year,
        'director_experience': 5,
        'director_is_prolific': 1,
        'director_is_veteran': 0,
        'genre_count': payload.genres.count('|') + 1,
        'is_multi_genre': 1 if payload.genres.count('|') >= 2 else 0,
        'is_popular_genre': 1 if primary_genre in ['Action', 'Comedy', 'Drama', 'Thriller', 'Adventure', 'Science Fiction'] else 0,
        'company_experience': 10,
        'is_major_studio': 0,
        'is_known_studio': 1 if payload.production_company in ['Warner Bros.', 'Universal Pictures', 'Marvel Studios', 'Pixar', 'DC Studios'] else 0,
        'is_optimal_runtime': 1 if 95 <= runtime_filled <= 125 else 0,
        'is_blockbuster_season': 0,
        'is_holiday_season': 0,
        'is_awards_season': 0,
        'is_sequel': 1 if payload.movie_title and any(c.isdigit() for c in payload.movie_title) else 0,
        'has_colon': 1 if payload.movie_title and ':' in payload.movie_title else 0,
        'title_length': len(payload.movie_title) if payload.movie_title else 20,
        'release_quarter': 2,
    }

    df_in = pd.DataFrame([data])

    try:
        pred = int(MODEL.predict(df_in)[0])
        proba = MODEL.predict_proba(df_in)[0]
        confidence = float(max(proba))
        success_prob = float(proba[1])
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Prediction error: {e}")

    return PredictResponse(
        prediction=pred,
        label="Success" if pred == 1 else "Fail",
        confidence=confidence,
        success_probability=success_prob
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
