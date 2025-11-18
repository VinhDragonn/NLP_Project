@echo off
echo ========================================
echo Starting NLP Backend + Flutter App
echo ========================================

REM Start NLP Backend in new window
start "NLP Backend Server" cmd /k "cd /d C:\Users\vinh0\Documents\movie_DO_AN\ml_backend && set NLP_PORT=8002 && python nlp_service.py"

echo.
echo ✅ NLP Backend started in separate window
echo ⏳ Waiting 3 seconds for backend to initialize...
timeout /t 3 /nobreak > nul

echo.
echo 🚀 Now you can run Flutter app in Android Studio
echo.
echo Press any key to stop backend server...
pause > nul

REM Kill Python process when done
taskkill /F /FI "WINDOWTITLE eq NLP Backend Server*" /T
