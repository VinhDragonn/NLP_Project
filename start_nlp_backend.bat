@echo off
echo ========================================
echo Starting NLP Backend Server
echo ========================================

cd /d C:\Users\vinh0\Documents\movie_DO_AN\ml_backend
set NLP_PORT=8002

echo.
echo Location: %CD%
echo Port: %NLP_PORT%
echo.
echo Starting server...
echo.

python nlp_service.py

pause
