# Sagawa POS - Point of Sale System

Sistem Point of Sale (POS) untuk Sagawa Group dengan Flutter sebagai frontend dan Go sebagai backend, menggunakan AstraDB (Cassandra) sebagai database.

## 🏗️ Arsitektur

- **Frontend**: Flutter (Mobile/Web/Desktop)
- **Backend**: Go dengan Fiber framework
- **Database**: AstraDB (Cassandra as a Service)

## 📋 Prerequisites

### Backend
- Go 1.21 atau lebih tinggi
- AstraDB account (gratis di [astra.datastax.com](https://astra.datastax.com))

### Frontend
- Flutter SDK 3.8.1 atau lebih tinggi
- Dart SDK
- Android Studio / VS Code dengan Flutter extension

## 🚀 Quick Start

### 1. Setup AstraDB

1. Buat akun di [AstraDB](https://astra.datastax.com)
2. Buat database baru:
   - Database name: `sagawa_pos`
   - Keyspace name: `sagawa_pos`
   - Cloud provider: Pilih sesuai preference
   - Region: Pilih yang terdekat

3. Download **Secure Connect Bundle**:
   - Di dashboard database, klik "Connect"
   - Download secure connect bundle
   - Simpan di folder `backend/`

4. Buat Application Token:
   - Di dashboard, pergi ke "Settings" → "Token Management"
   - Buat token baru dengan role "Database Administrator"
   - Simpan Client ID dan Client Secret

5. Setup tables di CQL Console:
```cql
USE sagawa_pos;

-- Buat type untuk order items
CREATE TYPE IF NOT EXISTS order_item (
    product_id UUID,
    name TEXT,
    quantity INT,
    price DOUBLE,
    subtotal DOUBLE
);

-- Buat tabel products
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY,
    name TEXT,
    description TEXT,
    price DOUBLE,
    category TEXT,
    stock INT,
    image_url TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Buat tabel customers
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY,
    name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Buat tabel orders
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY,
    order_number TEXT,
    customer_id UUID,
    items LIST<FROZEN<order_item>>,
    total_amount DOUBLE,
    status TEXT,
    payment_method TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Insert sample products
INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Nasi Goreng', 'Nasi goreng spesial', 25000, 'Main Course', 50, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Mie Goreng', 'Mie goreng spesial', 20000, 'Main Course', 50, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Es Teh Manis', 'Es teh manis segar', 5000, 'Beverages', 100, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Jus Jeruk', 'Jus jeruk segar', 10000, 'Beverages', 100, '', true, toTimestamp(now()), toTimestamp(now()));
```

### 2. Setup Backend

```bash
cd backend

# Install dependencies
go mod download

# Copy environment file
cp .env.example .env

# Edit .env dengan kredensial AstraDB Anda
# Gunakan text editor seperti nano, vim, atau notepad
nano .env
```

Update file `.env`:
```env
ASTRA_DB_ID=your_database_id
ASTRA_DB_REGION=your_region
ASTRA_DB_KEYSPACE=sagawa_pos
ASTRA_DB_USERNAME=your_client_id
ASTRA_DB_PASSWORD=your_client_secret
ASTRA_DB_SECURE_BUNDLE_PATH=./secure-connect-sagawa-pos.zip
PORT=8080
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

Jalankan backend:
```bash
go run main.go
```

Backend akan berjalan di `http://localhost:8080`

Test endpoint:
```bash
curl http://localhost:8080/health
```

### 3. Setup Frontend

```bash
cd frontend

# Install dependencies
flutter pub get

# Copy environment file
cp .env.example .env

# Edit .env jika diperlukan (default sudah benar untuk local development)
```

Jalankan aplikasi:
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

## 📁 Struktur Project

```
sagawa_pos/
├── backend/
│   ├── config/              # Database configuration
│   ├── handlers/            # Request handlers
│   ├── models/              # Data models
│   ├── routes/              # API routes
│   ├── main.go              # Application entry point
│   ├── go.mod               # Go dependencies
│   ├── .env                 # Environment variables
│   └── README.md
│
└── frontend/
    ├── lib/
    │   ├── models/          # Data models
    │   ├── services/        # API services
    │   ├── providers/       # State management
    │   ├── screens/         # UI screens
    │   └── main.dart        # App entry point
    ├── pubspec.yaml         # Flutter dependencies
    ├── .env                 # Environment variables
    └── README.md
```

## 🔌 API Endpoints

### Health Check
- `GET /health` - Check API status

### Products
- `GET /api/v1/products` - Get all products
- `GET /api/v1/products/:id` - Get product by ID
- `POST /api/v1/products` - Create new product
- `PUT /api/v1/products/:id` - Update product
- `DELETE /api/v1/products/:id` - Delete product

### Orders
- `GET /api/v1/orders` - Get all orders
- `GET /api/v1/orders/:id` - Get order by ID
- `POST /api/v1/orders` - Create new order
- `PATCH /api/v1/orders/:id/status` - Update order status

## 🎨 Fitur Aplikasi

### Frontend Features
- ✅ Daftar produk dengan filter kategori
- ✅ Keranjang belanja dengan management item
- ✅ Multiple payment methods
- ✅ Responsive design
- ✅ State management dengan Provider

### Backend Features
- ✅ RESTful API dengan Fiber
- ✅ AstraDB/Cassandra integration
- ✅ CORS support
- ✅ Error handling
- ✅ Environment-based configuration

## 🧪 Testing Backend API

### Get all products
```bash
curl http://localhost:8080/api/v1/products
```

### Create a product
```bash
curl -X POST http://localhost:8080/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ayam Goreng",
    "description": "Ayam goreng crispy",
    "price": 30000,
    "category": "Main Course",
    "stock": 30,
    "image_url": "",
    "is_active": true
  }'
```

### Create an order
```bash
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "00000000-0000-0000-0000-000000000000",
    "items": [
      {
        "product_id": "product-uuid-here",
        "name": "Nasi Goreng",
        "quantity": 2,
        "price": 25000,
        "subtotal": 50000
      }
    ],
    "payment_method": "Cash"
  }'
```

## 🐛 Troubleshooting

### Backend tidak bisa connect ke AstraDB
1. Pastikan secure connect bundle path sudah benar
2. Periksa kredensial (Client ID dan Secret)
3. Pastikan keyspace sudah dibuat di AstraDB
4. Check firewall/network settings

### Flutter tidak bisa connect ke backend
1. Pastikan backend sudah running
2. Untuk Android emulator, gunakan `http://10.0.2.2:8080` di `.env`
3. Untuk iOS simulator, gunakan `http://localhost:8080`
4. Untuk device fisik, gunakan IP address komputer

### Dependencies error
```bash
# Backend
cd backend
go mod tidy
go mod download

# Frontend
cd frontend
flutter clean
flutter pub get
```

## 📝 Environment Variables

### Backend (.env)
```env
ASTRA_DB_ID=               # Database ID dari AstraDB
ASTRA_DB_REGION=           # Region database
ASTRA_DB_KEYSPACE=         # Nama keyspace (sagawa_pos)
ASTRA_DB_USERNAME=         # Client ID dari token
ASTRA_DB_PASSWORD=         # Client Secret dari token
ASTRA_DB_SECURE_BUNDLE_PATH= # Path ke secure bundle
PORT=8080                  # Port backend
ALLOWED_ORIGINS=           # CORS origins
```

### Frontend (.env)
```env
API_BASE_URL=http://localhost:8080/api/v1  # Base URL backend API
```

## 📦 Build untuk Production

### Backend
```bash
cd backend
go build -o sagawa-pos-api main.go
```

### Flutter
```bash
cd frontend

# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## 🤝 Contributing

Silakan buat branch baru untuk setiap feature atau bugfix, kemudian buat Pull Request.

## 📄 License

Proprietary - Sagawa Group

## 👥 Team

Sagawa Group Development Team
