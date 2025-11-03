# Sagawa POS - Frontend

Frontend untuk sistem Point of Sale (POS) Sagawa Group menggunakan Flutter dengan **Clean Architecture**.

## 🏗️ Arsitektur

Aplikasi ini menggunakan **Clean Architecture** dengan pembagian yang jelas:

- **Core Layer**: Komponen inti yang digunakan di seluruh aplikasi
- **Features Layer**: Fitur-fitur aplikasi yang terstruktur

📖 **Dokumentasi lengkap struktur folder**: [FOLDER_STRUCTURE.md](FOLDER_STRUCTURE.md)

## 📂 Struktur Project

```
lib/
├── core/                    # Core components
│   ├── constants/          # App constants
│   ├── theme/              # App theme & colors
│   ├── errors/             # Error handling (exceptions & failures)
│   ├── utils/              # Utilities (helpers, logger)
│   ├── widgets/            # Reusable widgets (loading, error, empty)
│   └── di/                 # Dependency injection
│
├── features/               # Features (Clean Architecture)
│   ├── products/           # Product feature
│   │   ├── domain/        # Entities & repository interfaces
│   │   ├── data/          # Models, data sources, repository impl
│   │   └── presentation/  # Providers, pages, widgets
│   │
│   ├── cart/              # Cart feature
│   │   ├── domain/        # Cart entities
│   │   └── presentation/  # Cart provider, pages, widgets
│   │
│   └── orders/            # Orders feature
│       ├── domain/        # Order entities & repositories
│       ├── data/          # Order data layer
│       └── presentation/  # Order providers
│
└── main.dart               # App entry point
```

## 🚀 Teknologi

- **Flutter** - Cross-platform mobile framework
- **Provider** - State management
- **HTTP** - REST API client
- **ScreenUtil** - Responsive UI
- **Google Fonts** - Custom fonts
- **Clean Architecture** - Project structure

## 📋 Prerequisites

1. Flutter SDK 3.8.1 atau lebih tinggi
2. Dart SDK
3. Android Studio / VS Code dengan Flutter extension
4. Backend API sudah berjalan

## 🔧 Setup

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Setup Environment

```bash
# Copy environment file
cp .env.example .env

# Edit .env dengan URL backend
nano .env
```

Isi file `.env`:
```env
API_BASE_URL=http://localhost:8080/api/v1
```

**Note untuk testing:**
- Android Emulator: `http://10.0.2.2:8080/api/v1`
- iOS Simulator: `http://localhost:8080/api/v1`
- Physical Device: `http://YOUR_COMPUTER_IP:8080/api/v1`

### 3. Run Application

```bash
# Android
flutter run

# iOS
flutter run

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 🎨 Fitur

### ✅ Product Management
- Daftar produk dengan grid view
- Filter produk berdasarkan kategori
- Detail produk dengan gambar
- Informasi stok real-time

### ✅ Shopping Cart
- Tambah produk ke keranjang
- Ubah kuantitas item
- Hapus item dari keranjang
- Lihat total harga real-time

### ✅ Order Processing
- Pilih metode pembayaran (Cash, Credit Card, Debit Card, E-Wallet)
- Proses order dengan validasi
- Notifikasi sukses/error

### ✅ UI/UX
- Responsive design dengan ScreenUtil
- Custom theme dengan brand colors
- Loading states yang smooth
- Error handling dengan retry option
- Empty states yang informatif

## 📱 Screenshots

*(Add screenshots here)*

## 🏛️ Clean Architecture Layers

### Domain Layer
- **Entities**: Business objects (Product, Order, CartItem)
- **Repositories**: Interface untuk data operations

### Data Layer
- **Models**: Data models dengan serialization
- **Data Sources**: Remote API calls
- **Repositories**: Implementasi dari domain repositories

### Presentation Layer
- **Providers**: State management dengan Provider pattern
- **Pages**: Screens/Pages utama aplikasi
- **Widgets**: UI components spesifik feature

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/products/domain/entities/product_test.dart
```

## 🔨 Build untuk Production

### Android

```bash
# APK
flutter build apk --release

# App Bundle (untuk Google Play)
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

## 📝 Code Style & Best Practices

1. **Naming Convention**:
   - Classes: `PascalCase` (ProductCard, CartProvider)
   - Files: `snake_case` (product_card.dart, cart_provider.dart)
   - Variables: `camelCase` (productList, totalAmount)

2. **Import Order**:
   ```dart
   // 1. Dart SDK
   import 'dart:async';
   
   // 2. Flutter SDK
   import 'package:flutter/material.dart';
   
   // 3. External packages
   import 'package:provider/provider.dart';
   
   // 4. Internal files
   import '../domain/entities/product.dart';
   ```

3. **File Organization**:
   - Satu class per file
   - Group related functionality
   - Keep files < 300 lines

4. **Widget Structure**:
   - Prefer `const` constructors
   - Extract complex widgets
   - Use `Builder` untuk context issues

## 🐛 Troubleshooting

### Connection Error

**Problem**: `Failed to connect to backend`

**Solutions**:
1. Pastikan backend running di port 8080
2. Periksa `API_BASE_URL` di `.env`
3. Untuk Android emulator gunakan `10.0.2.2` bukan `localhost`
4. Disable firewall atau antivirus sementara

### Dependencies Error

```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Build Error

```bash
flutter clean
flutter pub get
cd android && ./gradlew clean  # Android only
cd ios && pod deintegrate && pod install  # iOS only
flutter run
```

### Hot Reload Not Working

```bash
# Restart app
flutter run

# Full restart
flutter run --no-hot
```

## 📚 Resources & Documentation

- **Project Documentation**:
  - [Folder Structure](FOLDER_STRUCTURE.md) - Detailed folder structure explanation
  - [API Documentation](../API_DOCUMENTATION.md) - Backend API endpoints

- **Flutter Resources**:
  - [Flutter Documentation](https://docs.flutter.dev/)
  - [Provider Package](https://pub.dev/packages/provider)
  - [Flutter ScreenUtil](https://pub.dev/packages/flutter_screenutil)

- **Clean Architecture**:
  - [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
  - [Flutter Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd/)

## 🔄 State Management Flow

```
User Action (UI)
      ↓
Provider (State Management)
      ↓
Repository (Domain Interface)
      ↓
Repository Implementation (Data Layer)
      ↓
Remote Data Source
      ↓
API Call (HTTP)
      ↓
Response → Data Source → Repository → Provider
      ↓
UI Update (notifyListeners)
```

## 🤝 Contributing

1. Follow Clean Architecture principles
2. Write tests for new features
3. Follow Dart/Flutter style guide
4. Document public APIs
5. Use meaningful commit messages

## 📄 License

Proprietary - Sagawa Group

## 👥 Team

Sagawa Group Development Team

---

**Happy Coding! 🚀**
