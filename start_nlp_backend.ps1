# Start NLP Backend Server
Write-Host "🚀 Starting NLP Backend Server..." -ForegroundColor Green

# Set environment variable
$env:NLP_PORT = 8002

# Navigate to backend directory
Set-Location "C:\Users\vinh0\Documents\movie_DO_AN\ml_backend"

# Start Python server
Write-Host "📍 Location: $(Get-Location)" -ForegroundColor Cyan
Write-Host "🔧 Port: $env:NLP_PORT" -ForegroundColor Cyan
Write-Host "⏳ Starting server..." -ForegroundColor Yellow

python nlp_service.py
