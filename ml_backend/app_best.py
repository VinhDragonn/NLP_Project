# ==========================================
# API DỰ ĐOÁN PHIM (BẢN SẠCH LOG - FINAL)
# ==========================================
import os
import warnings

# --- CẤU HÌNH TẮT CẢNH BÁO (QUAN TRỌNG) ---
# Đặt cái này lên đầu tiên để chặn mọi cảnh báo rác
os.environ["PYTHONWARNINGS"] = "ignore"
warnings.filterwarnings("ignore")
warnings.simplefilter(action='ignore', category=FutureWarning)
warnings.simplefilter(action='ignore', category=UserWarning)
# ------------------------------------------

from typing import List, Optional
from contextlib import asynccontextmanager

import pandas as pd
import numpy as np
import gdown
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Thư viện Machine Learning
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier, VotingClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from imblearn.under_sampling import RandomUnderSampler

# ===== CẤU HÌNH =====
# Tên file giữ nguyên để NLP Service không bị lỗi
CSV_FILENAME = "rotten_tomatoes_ENRICHED.csv"
# ID file chứa dữ liệu TMDB (Budget, Revenue, Popularity)
DRIVE_FILE_ID = "1gRNeO8VcJKqudnynfgnMb-v7fRqMOcpS"
RANDOM_STATE = 42

# ===== 1. HELPER CLASSES =====

class TargetEncoder(BaseEstimator, TransformerMixin):
    def __init__(self, col_name, target_name='success', smooth=10):
        self.col_name = col_name
        self.target_name = target_name
        self.smooth = smooth
        self.map_dict = {}
        self.global_mean = 0

    def fit(self, X, y):
        temp_df = X.copy()
        temp_df[self.target_name] = y
        stats = temp_df.groupby(self.col_name)[self.target_name].agg(['mean', 'count'])
        self.global_mean = y.mean()
        smoothed = (stats['mean'] * stats['count'] + self.global_mean * self.smooth) / (stats['count'] + self.smooth)
        self.map_dict = smoothed.to_dict()
        return self

    def transform(self, X):
        return X[self.col_name].map(self.map_dict).fillna(self.global_mean).values.reshape(-1, 1)

def ensure_data_is_latest():
    """
    Kiểm tra file hiện tại. Nếu là file cũ (thiếu budget) -> Xóa đi tải lại file xịn.
    """
    should_download = False

    if not os.path.exists(CSV_FILENAME):
        should_download = True
        print("📉 Chưa thấy file dữ liệu. Đang tải mới...")
    else:
        try:
            # Đọc thử 5 dòng xem có cột budget chưa
            df_check = pd.read_csv(CSV_FILENAME, nrows=5)
            if 'budget' not in df_check.columns:
                print("⚠️ Phát hiện file cũ (thiếu Budget). Đang cập nhật bản mới...")
                os.remove(CSV_FILENAME)
                should_download = True
            else:
                print("✅ File dữ liệu đã là phiên bản mới nhất.")
        except:
            should_download = True

    if should_download:
        url = f'https://drive.google.com/uc?id={DRIVE_FILE_ID}'
        gdown.download(url, CSV_FILENAME, quiet=False)
        print("✅ Tải xong dữ liệu Super Enriched!")

def engineer_features(df):
    """Xử lý đặc trưng (Feature Engineering)"""
    # 1. Xử lý chuỗi
    df['primary_director'] = df['directors'].astype(str).str.split(',').str[0].str.strip()
    df['clean_company'] = df['production_company'].astype(str).str.strip()
    df['primary_genre'] = df['genres'].astype(str).str.split('|').str[0]

    valid_ratings = ['PG', 'R', 'PG-13', 'G']
    df['content_rating'] = df['content_rating'].apply(lambda x: x if x in valid_ratings else 'Unrated')

    # 2. Xử lý số
    df['runtime'] = df['runtime'].fillna(df['runtime'].median())
    df['release_year'] = pd.to_datetime(df['original_release_date'], errors='coerce').dt.year.fillna(2024)

    # 3. LOGIC TÀI CHÍNH (QUAN TRỌNG)
    if 'budget' not in df.columns: df['budget'] = 0
    if 'tmdb_popularity' not in df.columns: df['tmdb_popularity'] = 0

    # Cột đánh dấu: Phim này có dữ liệu tiền thật hay không?
    df['has_financial_data'] = (df['budget'] > 1000).astype(int)

    # Log Transform
    df['budget_log'] = np.log1p(df['budget'].fillna(0))
    df['popularity_log'] = np.log1p(df['tmdb_popularity'].fillna(0))

    # 4. Văn bản & Sequel
    if 'keywords' not in df.columns: df['keywords'] = ''
    if 'movie_info' not in df.columns: df['movie_info'] = ''
    df['text_content'] = df['keywords'].fillna('') + " " + df['movie_info'].fillna('')

    df['is_sequel'] = df['movie_title'].astype(str).str.contains(
        r'\s\d+$|II|III|IV|Part\s\d|:.*|Returns|Saga', case=False, regex=True).astype(int)

    return df

# ===== 2. CORE TRAINING =====

def load_and_train():
    ensure_data_is_latest()

    print("🚀 Loading data & Training (FULL STRATEGY)...")
    df = pd.read_csv(CSV_FILENAME)

    # Giữ lại toàn bộ phim, kể cả phim thiếu budget
    df = df.dropna(subset=["tomatometer_rating"])
    print(f"DEBUG: Đang học trên tổng số {len(df)} bộ phim.")

    df["success"] = (df["tomatometer_rating"] >= 60).astype(int)

    df = engineer_features(df)

    # Cân bằng dữ liệu
    rus = RandomUnderSampler(random_state=RANDOM_STATE)
    X_bal, y_bal = rus.fit_resample(df, df["success"])

    X_train, X_test, y_train, y_test = train_test_split(
        X_bal, y_bal, test_size=0.2, random_state=RANDOM_STATE, stratify=y_bal
    )

    # --- PIPELINE ---
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', StandardScaler(), ['runtime', 'release_year', 'is_sequel', 'budget_log', 'popularity_log', 'has_financial_data']),
            ('dir_score', Pipeline([('enc', TargetEncoder(col_name='primary_director', smooth=5))]), ['primary_director']),
            ('com_score', Pipeline([('enc', TargetEncoder(col_name='clean_company', smooth=10))]), ['clean_company']),
            ('txt', Pipeline([('tfidf', TfidfVectorizer(max_features=150, stop_words='english'))]), 'text_content'),
            ('cat', Pipeline([('onehot', OneHotEncoder(handle_unknown='ignore', sparse_output=False))]), ['content_rating', 'primary_genre'])
        ]
    )

    # Tăng sức mạnh Random Forest lên vì dữ liệu giờ to hơn
    rf = RandomForestClassifier(n_estimators=400, max_depth=20, n_jobs=-1, random_state=RANDOM_STATE)
    knn = KNeighborsClassifier(n_neighbors=20, n_jobs=-1)

    ensemble = VotingClassifier(
        estimators=[('RF', rf), ('KNN', knn)],
        voting='soft'
    )

    model = Pipeline(steps=[("preprocess", preprocessor), ("clf", ensemble)])

    print("⏳ Training model...")
    model.fit(X_train, y_train)

    acc = model.score(X_test, y_test)
    print(f"✅ ACCURACY: {acc:.2%}")

    return model

# ===== 3. API SETUP =====

class MovieFeatures(BaseModel):
    movie_title: Optional[str] = Field(None)
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

@asynccontextmanager
async def lifespan(app: FastAPI):
    global MODEL
    print(f"\n{'='*60}")
    print("STARTING SERVER")
    print(f"{'='*60}\n")
    MODEL = load_and_train()
    yield

app = FastAPI(title="Movie Predictor", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/predict", response_model=PredictResponse)
def predict(payload: MovieFeatures):
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Model not ready")

    # --- LOGIC AUTO-FILL (Ước lượng kinh phí) ---
    est_budget = 20_000_000
    est_pop = 40

    # Hãng lớn
    giants = ['Disney', 'Marvel', 'Warner', 'Universal', 'Paramount', 'Fox', 'Sony', 'Netflix', 'Amazon']
    if any(g.lower() in payload.production_company.lower() for g in giants):
        est_budget = 150_000_000
        est_pop = 200

    # Thể loại đắt tiền
    if 'Action' in payload.genres or 'Adventure' in payload.genres or 'Sci-Fi' in payload.genres:
        est_budget = max(est_budget, 100_000_000)

    # Hoạt hình lớn
    if 'Animation' in payload.genres and ('Disney' in payload.production_company or 'Pixar' in payload.production_company):
        est_budget = 200_000_000

    # Phim Indie
    if 'Indie' in payload.production_company or 'Art House' in payload.genres:
        est_budget = 5_000_000

    data = {
        'movie_title': [payload.movie_title if payload.movie_title else ""],
        'directors': [payload.directors],
        'genres': [payload.genres],
        'production_company': [payload.production_company],
        'runtime': [payload.runtime],
        'original_release_date': [f"{int(payload.release_year)}-01-01"],
        'content_rating': ["PG-13"],
        'keywords': [""],
        'movie_info': [payload.movie_title],
        'budget': [est_budget],
        'tmdb_popularity': [est_pop]
    }

    df_in = pd.DataFrame(data)
    df_in = engineer_features(df_in)

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