#!/bin/bash

# Setup Script untuk Linux/Mac

echo "🚀 Sagawa POS Setup Script"
echo "================================"
echo ""

# Check Go installation
echo "Checking Go installation..."
if command -v go &> /dev/null; then
    GO_VERSION=$(go version)
    echo "✓ Go installed: $GO_VERSION"
else
    echo "✗ Go not found. Please install Go 1.21 or higher"
    exit 1
fi

# Check Flutter installation
echo "Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    echo "✓ Flutter installed"
else
    echo "✗ Flutter not found. Please install Flutter SDK"
    exit 1
fi

echo ""
echo "Setting up Backend..."
cd backend

# Setup backend .env
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created backend .env file"
    echo "⚠ Please edit backend/.env with your AstraDB credentials"
else
    echo "✓ Backend .env already exists"
fi

# Install Go dependencies
echo "Installing Go dependencies..."
if go mod download; then
    echo "✓ Go dependencies installed"
else
    echo "✗ Failed to install Go dependencies"
    cd ..
    exit 1
fi

cd ..

echo ""
echo "Setting up Frontend..."
cd frontend

# Setup frontend .env
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created frontend .env file"
else
    echo "✓ Frontend .env already exists"
fi

# Install Flutter dependencies
echo "Installing Flutter dependencies..."
if flutter pub get; then
    echo "✓ Flutter dependencies installed"
else
    echo "✗ Failed to install Flutter dependencies"
    cd ..
    exit 1
fi

cd ..

echo ""
echo "================================"
echo "✓ Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit backend/.env with your AstraDB credentials"
echo "2. Download secure connect bundle from AstraDB"
echo "3. Place the bundle in backend/ folder"
echo "4. Setup tables in AstraDB (see README.md)"
echo "5. Run backend: cd backend && go run main.go"
echo "6. Run frontend: cd frontend && flutter run"
echo ""
