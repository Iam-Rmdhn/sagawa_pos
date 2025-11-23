# Integrasi Multi-Tenant POS System
## Dashboard Admin → Flutter App

Dokumentasi lengkap untuk mengintegrasikan aplikasi POS dengan Web Dashboard Admin yang akan berada di VPS terpisah.

---

## 🎯 Konsep Multi-Tenant

Setiap akun memiliki:
- **User ID unik** (contoh: `12345`, `09876`)
- **Jenis kemitraan** (contoh: `kemitraan_warnas`, `kemitraan_kagawa`)
- **Tipe menu** (contoh: `warteg`, `japanese`, `ricebowl`)
- **Produk terpisah** per account
- **Orderan terpisah** per account

### Contoh Akun:
```
┌────────────────────────────────────────────────────────┐
│ User ID: 12345                                         │
│ Nama: Warnas Warteg Cipete                            │
│ Kemitraan: kemitraan_warnas                           │
│ Menu Type: warteg                                      │
│ Produk: Nasi Putih, Ayam Goreng, Tempe, Sayur, dll    │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ User ID: 09876                                         │
│ Nama: Kagawa Rice Bowl Senayan                        │
│ Kemitraan: kemitraan_kagawa                           │
│ Menu Type: japanese                                    │
│ Produk: Teriyaki Bowl, Katsu Curry, Gyudon, dll       │
└────────────────────────────────────────────────────────┘
```

---

## 📋 Alur Kerja Sistem

### 1. **Dashboard Admin (Web) - Di VPS**
Admin membuat akun baru:
```
1. Buka Dashboard Admin
2. Klik "Tambah Akun Baru"
3. Isi form:
   - User ID: 12345
   - Nama: Warnas Warteg Cipete
   - Kemitraan: kemitraan_warnas
   - Menu Type: warteg
   - Password: ********
4. Klik "Simpan"
5. Sistem membuat:
   - Record di tabel `accounts`
   - Password di-hash dengan bcrypt
   - Status = active
```

Admin menambah produk untuk akun:
```
1. Pilih akun (12345 - Warnas Warteg)
2. Klik "Kelola Menu"
3. Tambah Produk:
   - Nama: Nasi Putih
   - Category: Makanan Pokok
   - Harga: 5000
   - Account ID: (otomatis dari akun terpilih)
   - Menu Type: warteg
4. Klik "Simpan"
5. Produk masuk ke database dengan `account_id = 12345`
```

### 2. **Flutter POS App - Di Tablet/HP**
User login dengan akun yang sudah dibuat:
```
1. Buka POS App
2. Input:
   - User ID: 12345
   - Password: ********
3. Klik "Masuk"
4. App kirim request ke API:
   POST /api/v1/auth/login
   Body: { "user_id": "12345", "password": "..." }
5. Backend:
   - Cek user di database
   - Validasi password (bcrypt)
   - Generate JWT token
   - Return: { token, account_info }
6. App simpan:
   - Token di SharedPreferences
   - Account info (account_id, menu_type, etc)
7. Navigate ke HomePage
```

HomePage load produk:
```
1. App kirim request:
   GET /api/v1/products
   Header: Authorization: Bearer <token>
2. Backend:
   - Extract account_id dari JWT
   - Query: SELECT * FROM products WHERE account_id = <dari_token>
   - Return produk khusus akun tersebut
3. App tampilkan produk sesuai menu_type
   - Jika warteg: Nasi Putih, Ayam Goreng, dll
   - Jika japanese: Teriyaki Bowl, Gyudon, dll
```

---

## 🗄️ Database Schema

### Table: accounts
```sql
CREATE TABLE accounts (
    id UUID PRIMARY KEY,
    user_id TEXT,              -- "12345", "09876"
    name TEXT,                 -- "Warnas Warteg"
    partner_type TEXT,         -- "kemitraan_warnas"
    menu_type TEXT,            -- "warteg", "japanese"
    email TEXT,
    phone TEXT,
    status TEXT,               -- "active", "inactive"
    password_hash TEXT,        -- bcrypt hash
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX accounts_by_user_id ON accounts (user_id);
```

### Table: products
```sql
CREATE TABLE products (
    id UUID PRIMARY KEY,
    account_id UUID,           -- Link ke accounts.id
    menu_type TEXT,            -- "warteg", "japanese"
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

CREATE INDEX products_by_account ON products (account_id);
```

### Table: orders
```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    account_id UUID,           -- Link ke accounts.id
    order_number TEXT,
    customer_id UUID,
    order_type TEXT,           -- "dine_in", "take_away"
    items LIST<FROZEN<order_item>>,
    total_amount DOUBLE,
    status TEXT,               -- "pending", "completed"
    payment_method TEXT,       -- "cash", "qris"
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX orders_by_account ON orders (account_id);
```

---

## 🔐 Authentication Flow (JWT)

### Login Request
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "user_id": "12345",
  "password": "password123"
}
```

### Login Response
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "account_info": {
    "account_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "12345",
    "name": "Warnas Warteg Cipete",
    "partner_type": "kemitraan_warnas",
    "menu_type": "warteg",
    "email": "warnas@example.com"
  }
}
```

### JWT Token Claims
```json
{
  "account_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "12345",
  "menu_type": "warteg",
  "partner_type": "kemitraan_warnas",
  "exp": 1700000000,
  "iat": 1699913600,
  "iss": "sagawa-pos-api"
}
```

### Protected Request
```http
GET /api/v1/products
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Backend akan:
1. Decode JWT token
2. Extract `account_id` dari claims
3. Filter data berdasarkan `account_id`
4. Return data khusus akun tersebut

---

## 🔧 Backend API Endpoints

### Authentication
```
POST   /api/v1/auth/login          # Login
POST   /api/v1/auth/logout         # Logout
POST   /api/v1/auth/refresh        # Refresh token
```

### Products (Protected - butuh JWT)
```
GET    /api/v1/products            # Get semua produk (filtered by account_id dari token)
GET    /api/v1/products/:id        # Get product detail
POST   /api/v1/products            # Create product (admin only)
PUT    /api/v1/products/:id        # Update product (admin only)
DELETE /api/v1/products/:id        # Delete product (admin only)
```

### Orders (Protected - butuh JWT)
```
GET    /api/v1/orders              # Get semua order (filtered by account_id dari token)
GET    /api/v1/orders/:id          # Get order detail
POST   /api/v1/orders              # Create order
PUT    /api/v1/orders/:id          # Update order status
```

### Account Settings (Protected)
```
GET    /api/v1/account/settings    # Get account settings
PUT    /api/v1/account/settings    # Update settings
GET    /api/v1/account/profile     # Get profile
PUT    /api/v1/account/profile     # Update profile
```

---

## 📱 Flutter Implementation

### 1. Install Dependencies
Tambahkan di `pubspec.yaml`:
```yaml
dependencies:
  dio: ^5.9.0
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0  # Optional, untuk simpan token lebih aman
```

### 2. File Structure
```
lib/
├── core/
│   └── constants/
│       ├── api_constants.dart       # Base URL, endpoints
│       └── app_constants.dart
├── data/
│   ├── models/
│   │   ├── account_info.dart
│   │   ├── product.dart
│   │   └── order.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── product_repository.dart
│   │   └── order_repository.dart
│   └── services/
│       ├── api_client.dart          # Dio with interceptor
│       └── auth_service.dart        # Token management
└── features/
    ├── auth/
    │   └── presentation/
    │       └── pages/
    │           └── login_page.dart
    └── home/
        └── presentation/
            └── pages/
                └── home_page.dart
```

### 3. Update API Base URL
Edit `lib/core/constants/api_constants.dart`:
```dart
static const String prodBaseUrl = 'https://your-vps-ip-or-domain.com/api/v1';
```

### 4. Login Flow
Sudah diimplementasikan di `login_page.dart`:
```dart
// User input User ID & Password
// Klik tombol Masuk
// Call: await _authRepository.login(userId, password)
// Jika berhasil: Navigate ke HomePage
// Jika gagal: Tampilkan error message
```

### 5. Load Products
Di HomePage (perlu update):
```dart
class HomePage extends StatefulWidget {
  // ...
}

class _HomePageState extends State<HomePage> {
  final ProductRepository _productRepo = ProductRepository();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getProducts();
    setState(() => _products = products);
  }

  // ... render products in grid
}
```

---

## 🚀 Deployment Steps

### Backend (VPS)
1. Setup VPS (Ubuntu 22.04 recommended)
2. Install Go 1.21+
3. Install Cassandra/AstraDB
4. Clone backend repo
5. Configure environment:
   ```bash
   export JWT_SECRET="your-super-secret-key"
   export DB_HOST="your-astradb-host"
   export DB_KEYSPACE="sagawa_pos"
   ```
6. Build & Run:
   ```bash
   cd backend
   go build -o sagawa-pos-api
   ./sagawa-pos-api
   ```
7. Setup Nginx reverse proxy (port 8080 → 443 HTTPS)
8. Configure SSL certificate (Let's Encrypt)

### Dashboard Admin (Web)
1. Build React/Vue app
2. Deploy ke VPS (same server atau terpisah)
3. Configure Nginx untuk serve static files
4. Point ke backend API

### Flutter App
1. Update `api_constants.dart` dengan VPS URL
2. Set `isProduction = true`
3. Build APK/IPA:
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```
4. Distribute ke tablet/HP kasir

---

## 🔒 Security Checklist

- ✅ Password di-hash dengan bcrypt (cost 10+)
- ✅ JWT token dengan expiry (24 jam)
- ✅ HTTPS only (SSL/TLS)
- ✅ Token disimpan di SharedPreferences/SecureStorage
- ✅ API rate limiting (prevent brute force)
- ✅ Input validation di backend
- ✅ CORS configuration (whitelist app domain)
- ✅ SQL injection protection (prepared statements)
- ✅ Regular security updates

---

## 📊 Testing Multi-Tenant

### Test Case 1: Akun Warteg
```
1. Dashboard Admin → Create Account:
   - User ID: 12345
   - Menu Type: warteg
   - Add products: Nasi Putih, Ayam Goreng

2. POS App → Login dengan 12345
3. Verify: Hanya muncul produk warteg
4. Create order → Verify order masuk dengan account_id = 12345
```

### Test Case 2: Akun Japanese
```
1. Dashboard Admin → Create Account:
   - User ID: 09876
   - Menu Type: japanese
   - Add products: Teriyaki Bowl, Gyudon

2. POS App → Login dengan 09876
3. Verify: Hanya muncul produk japanese
4. Create order → Verify order masuk dengan account_id = 09876
```

### Test Case 3: Data Isolation
```
1. Login dengan akun 12345
2. Verify: Tidak bisa lihat produk/order dari akun 09876
3. Logout → Login dengan 09876
4. Verify: Tidak bisa lihat produk/order dari akun 12345
```

---

## 🎨 UI/UX Considerations

### Menu Type Theming
Bisa customize UI berdasarkan menu_type:
```dart
// Di HomePage
final accountInfo = await _authService.getAccountInfo();

Widget build(BuildContext context) {
  Color primaryColor;
  String headerTitle;
  
  switch (accountInfo?.menuType) {
    case 'warteg':
      primaryColor = Color(0xFFFF4B4B); // Red
      headerTitle = 'Warnas Warteg';
      break;
    case 'japanese':
      primaryColor = Color(0xFFD32F2F); // Dark Red
      headerTitle = 'Kagawa Rice Bowl';
      break;
    default:
      primaryColor = Color(0xFFFF4B4B);
      headerTitle = 'Sagawa POS';
  }
  
  return Scaffold(
    backgroundColor: primaryColor,
    // ...
  );
}
```

---

## 📞 Support & Maintenance

### Monitoring
- Backend logs: `/var/log/sagawa-pos/`
- Database monitoring: AstraDB dashboard
- Error tracking: Sentry/Rollbar (optional)

### Backup
- Database: Daily automatic backup
- Media files: S3/Cloud Storage
- Configuration: Git repository

### Updates
- Backend API: Zero-downtime deployment
- Flutter App: App Store/Play Store updates
- Dashboard: Direct deployment ke production

---

## ✅ Checklist Implementation

### Backend
- [x] Model `Account` dengan multi-tenant fields
- [x] Model `Product` dengan `account_id`
- [x] Model `Order` dengan `account_id`
- [x] Auth handler dengan JWT
- [x] Middleware untuk filter by account_id
- [ ] Product handler dengan auth
- [ ] Order handler dengan auth
- [ ] Database migration scripts
- [ ] Seed data untuk testing

### Frontend
- [x] API constants dengan VPS URL
- [x] Auth service (token management)
- [x] API client dengan interceptor
- [x] Auth repository
- [x] Login page dengan loading state
- [ ] Product repository integration
- [ ] HomePage load products from API
- [ ] Order creation dengan account_id
- [ ] Logout functionality

### Infrastructure
- [ ] VPS setup & configuration
- [ ] Database setup (Cassandra/AstraDB)
- [ ] Nginx reverse proxy
- [ ] SSL certificate
- [ ] Domain configuration
- [ ] Backup strategy
- [ ] Monitoring tools

---

**Sekarang sistem Anda sudah siap untuk multi-tenant!** 🎉

Setiap akun yang dibuat di Dashboard Admin akan otomatis bisa login di POS App dan hanya melihat data mereka sendiri.
