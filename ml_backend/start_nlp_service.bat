@echo off
echo ========================================
echo Starting NLP Service for Movie Search
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8 or higher
    pause
    exit /b 1
)

echo [1/3] Checking dependencies...
pip show fastapi >nul 2>&1
if errorlevel 1 (
    echo Installing dependencies...
    pip install -r requirements.txt
) else (
    echo Dependencies already installed
)

echo.
echo [2/3] Testing NLP algorithms...
python test_nlp_algorithms.py
if errorlevel 1 (
    echo ERROR: NLP algorithms test failed
    pause
    exit /b 1
)

echo.
echo [3/3] Starting NLP Service on port 8001...
echo.
echo ========================================
echo NLP Service is running!
echo API Documentation: http://localhost:8001/docs
echo Health Check: http://localhost:8001/health
echo ========================================
echo.
echo Press Ctrl+C to stop the service
echo.

python nlp_service.py

pause
