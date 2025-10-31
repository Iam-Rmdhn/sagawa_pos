# Sagawa POS Backend

Backend API untuk sistem POS Sagawa Group menggunakan Go dan AstraDB.

## Teknologi

- **Go** (Golang) - Backend framework menggunakan Fiber
- **AstraDB** - Cassandra database as a service
- **Fiber** - Web framework untuk Go

## Setup

### Prerequisites

1. Go 1.21 atau lebih tinggi
2. AstraDB account dan database
3. Secure Connect Bundle dari AstraDB

### Instalasi

1. Clone repository dan masuk ke folder backend:
```bash
cd backend
```

2. Install dependencies:
```bash
go mod download
```

3. Copy file `.env.example` menjadi `.env`:
```bash
cp .env.example .env
```

4. Download **Secure Connect Bundle** dari AstraDB console dan letakkan di folder `backend`

5. Update file `.env` dengan kredensial AstraDB Anda:
```env
ASTRA_DB_ID=your_database_id
ASTRA_DB_REGION=your_region
ASTRA_DB_KEYSPACE=sagawa_pos
ASTRA_DB_USERNAME=your_client_id
ASTRA_DB_PASSWORD=your_client_secret
ASTRA_DB_SECURE_BUNDLE_PATH=./secure-connect-bundle.zip
PORT=8080
```

### Membuat Keyspace dan Tables di AstraDB

Login ke AstraDB CQL Console dan jalankan:

```cql
-- Buat keyspace (jika belum ada)
CREATE KEYSPACE IF NOT EXISTS sagawa_pos 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

-- Gunakan keyspace
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
```

## Menjalankan Server

```bash
go run main.go
```

Server akan berjalan di `http://localhost:8080`

## API Endpoints

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

## Struktur Project

```
backend/
├── config/          # Database configuration
├── handlers/        # Request handlers
├── models/          # Data models
├── routes/          # API routes
├── main.go          # Application entry point
├── go.mod           # Go module file
└── .env             # Environment variables
```
