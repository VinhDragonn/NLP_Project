# Movie Success Predictor Backend (FastAPI)

This FastAPI service trains a RandomForest model from Rotten Tomatoes data and exposes a `/predict` API for the Flutter app to use.

## Requirements
- Python 3.10+

## Setup
```bash
# 1) Create & activate venv (Windows PowerShell)
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# 2) Install dependencies
pip install -r ml_backend/requirements.txt
```

## Configure CSV path (optional)
By default the app tries to load:
```
C:/Users/vinh0/Documents/aaaaaaaaaaaaaaaaaaaaaaaaaaa/rotten_tomatoes_movies.csv
```
If your CSV is at a different path, set environment variable before running:
```powershell
$env:RT_CSV_PATH = "C:/path/to/rotten_tomatoes_movies.csv"
```

## Run the server
```bash
python ml_backend/app_best.py
# or
uvicorn ml_backend.app:app --host 0.0.0.0 --port 8000 --reload
```

The server will print a classification report in the console and be available at:
- Health: http://127.0.0.1:8000/health
- Swagger UI: http://127.0.0.1:8000/docs

## Flutter configuration
In your project's `.env` we added:
```
ML_URL="http://127.0.0.1:8000"
```
The Flutter service `lib/services/ml_predict_service.dart` reads this value using `flutter_dotenv`. Ensure your Flutter app runs after the `.env` is loaded (already done in `lib/main.dart`).

## Request format
POST `/predict`
```json
{
  "movie_title": "Inception",
  "directors": "Christopher Nolan",
  "genres": "Action & Adventure|Drama|Sci-Fi & Fantasy",
  "production_company": "Warner Bros.",
  "runtime": 148,
  "release_year": 2010,
  "audience_rating": 86,
  "tomatometer_count": 100,
  "audience_count": 500000
}
```

Response
```json
{
  "prediction": 1,
  "label": "Success"
}
```
