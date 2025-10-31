# Setup Script untuk Windows (PowerShell)

Write-Host "🚀 Sagawa POS Setup Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Check Go installation
Write-Host "Checking Go installation..." -ForegroundColor Yellow
$goVersion = go version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Go installed: $goVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Go not found. Please install Go 1.21 or higher" -ForegroundColor Red
    exit 1
}

# Check Flutter installation
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Flutter installed" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter not found. Please install Flutter SDK" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Setting up Backend..." -ForegroundColor Cyan
Set-Location backend

# Setup backend .env
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "✓ Created backend .env file" -ForegroundColor Green
    Write-Host "⚠ Please edit backend/.env with your AstraDB credentials" -ForegroundColor Yellow
} else {
    Write-Host "✓ Backend .env already exists" -ForegroundColor Green
}

# Install Go dependencies
Write-Host "Installing Go dependencies..." -ForegroundColor Yellow
go mod download
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Go dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Go dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Set-Location ..

Write-Host ""
Write-Host "Setting up Frontend..." -ForegroundColor Cyan
Set-Location frontend

# Setup frontend .env
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "✓ Created frontend .env file" -ForegroundColor Green
} else {
    Write-Host "✓ Frontend .env already exists" -ForegroundColor Green
}

# Install Flutter dependencies
Write-Host "Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Flutter dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Flutter dependencies" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Set-Location ..

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "✓ Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit backend/.env with your AstraDB credentials"
Write-Host "2. Download secure connect bundle from AstraDB"
Write-Host "3. Place the bundle in backend/ folder"
Write-Host "4. Setup tables in AstraDB (see README.md)"
Write-Host "5. Run backend: cd backend && go run main.go"
Write-Host "6. Run frontend: cd frontend && flutter run"
Write-Host ""
