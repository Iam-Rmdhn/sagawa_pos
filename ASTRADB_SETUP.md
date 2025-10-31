# Setup AstraDB untuk Sagawa POS

Panduan lengkap untuk setup database AstraDB untuk aplikasi Sagawa POS.

## 1. Buat Akun AstraDB

1. Kunjungi [https://astra.datastax.com](https://astra.datastax.com)
2. Klik "Get Started Free" atau "Sign Up"
3. Daftar menggunakan email atau akun Google/GitHub
4. Verifikasi email Anda

## 2. Buat Database Baru

1. Login ke dashboard AstraDB
2. Klik tombol **"Create Database"**
3. Isi form dengan informasi berikut:
   - **Database name**: `sagawa_pos`
   - **Keyspace name**: `sagawa_pos`
   - **Provider**: Pilih cloud provider (AWS/GCP/Azure)
   - **Region**: Pilih region terdekat dengan lokasi Anda
4. Klik **"Create Database"**
5. Tunggu beberapa menit hingga database status menjadi **"Active"**

## 3. Download Secure Connect Bundle

Secure Connect Bundle adalah file yang berisi sertifikat dan konfigurasi untuk koneksi aman ke AstraDB.

1. Di dashboard, pilih database `sagawa_pos`
2. Klik tab **"Connect"**
3. Pilih **"Connect using a driver"**
4. Pilih **"Node.js"** atau driver lainnya (bundle sama untuk semua)
5. Klik **"Download Bundle"**
6. Simpan file `secure-connect-sagawa-pos.zip` ke folder `backend/` di project Anda

## 4. Buat Application Token

Application Token digunakan untuk autentikasi ke database.

1. Di dashboard AstraDB, klik menu **"Settings"** (icon gear)
2. Pilih **"Token Management"** di sidebar
3. Klik **"Generate Token"**
4. Pilih role **"Database Administrator"**
5. Klik **"Generate Token"**
6. **PENTING**: Salin dan simpan informasi berikut:
   - **Client ID** (akan digunakan sebagai username)
   - **Client Secret** (akan digunakan sebagai password)
   - **Token** (opsional, untuk REST API)

⚠️ **PERHATIAN**: Client Secret hanya ditampilkan sekali! Pastikan Anda menyimpannya dengan aman.

## 5. Setup Tables di CQL Console

### Cara 1: Menggunakan CQL Console (Recommended)

1. Di dashboard database, klik tab **"CQL Console"**
2. Tunggu console terbuka
3. Copy dan paste isi file `backend/setup_database.cql`
4. Jalankan perintah satu per satu atau semua sekaligus
5. Verifikasi dengan menjalankan:
   ```cql
   SELECT COUNT(*) FROM products;
   ```

### Cara 2: Menggunakan File CQL

Jika Anda prefer menggunakan file:

1. Buka file `backend/setup_database.cql`
2. Copy semua isinya
3. Paste ke CQL Console
4. Tekan Enter untuk eksekusi

## 6. Konfigurasi Backend

1. Di folder `backend/`, copy file environment:
   ```bash
   cp .env.example .env
   ```

2. Edit file `.env` dengan text editor:
   ```env
   ASTRA_DB_ID=your-database-id
   ASTRA_DB_REGION=your-region
   ASTRA_DB_KEYSPACE=sagawa_pos
   ASTRA_DB_USERNAME=your-client-id
   ASTRA_DB_PASSWORD=your-client-secret
   ASTRA_DB_SECURE_BUNDLE_PATH=./secure-connect-sagawa-pos.zip
   PORT=8080
   ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
   ```

3. Isi dengan informasi yang Anda dapatkan:
   - `ASTRA_DB_ID`: Database ID dari dashboard
   - `ASTRA_DB_REGION`: Region yang Anda pilih (contoh: us-east-1)
   - `ASTRA_DB_USERNAME`: Client ID dari token
   - `ASTRA_DB_PASSWORD`: Client Secret dari token
   - `ASTRA_DB_SECURE_BUNDLE_PATH`: Path ke secure bundle

### Cara Mendapatkan Database ID

1. Di dashboard AstraDB
2. Pilih database `sagawa_pos`
3. Database ID ada di URL browser atau di bagian "Database Details"
4. Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Cara Mendapatkan Region

1. Di dashboard, lihat informasi database
2. Region ditampilkan di card database
3. Contoh: `us-east-1`, `asia-southeast1`, dll.

## 7. Verifikasi Koneksi

1. Pastikan secure bundle ada di folder `backend/`
2. Pastikan file `.env` sudah diisi dengan benar
3. Jalankan backend:
   ```bash
   cd backend
   go run main.go
   ```

4. Jika berhasil, Anda akan melihat:
   ```
   Server starting on port 8080
   ```

5. Test koneksi:
   ```bash
   curl http://localhost:8080/api/v1/products
   ```

## 8. Troubleshooting

### Error: "Failed to connect to AstraDB"

**Penyebab:**
- Secure bundle path salah
- Kredensial tidak valid
- Keyspace belum dibuat

**Solusi:**
1. Periksa path secure bundle di `.env`
2. Pastikan Client ID dan Secret benar
3. Verifikasi keyspace `sagawa_pos` ada di database

### Error: "No such keyspace"

**Penyebab:**
- Keyspace belum dibuat

**Solusi:**
1. Buka CQL Console
2. Jalankan:
   ```cql
   CREATE KEYSPACE IF NOT EXISTS sagawa_pos 
   WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
   ```

### Error: "Table not found"

**Penyebab:**
- Tables belum dibuat

**Solusi:**
1. Jalankan script `backend/setup_database.cql` di CQL Console

### Error: "Connection timeout"

**Penyebab:**
- Network/firewall issue
- Database sedang hibernating (free tier)

**Solusi:**
1. Periksa koneksi internet
2. Di dashboard, pastikan database status "Active"
3. Jika hibernating, tunggu beberapa menit untuk database wake up

## 9. Tips untuk Free Tier

AstraDB free tier memiliki batasan:

- **Storage**: 5 GB
- **Monthly I/O**: 1 million reads/writes
- **Hibernation**: Database akan hibernate setelah tidak aktif beberapa hari

**Tips:**
1. Database akan otomatis wake up saat diakses (butuh 1-2 menit)
2. Untuk development, free tier sangat cukup
3. Monitor usage di dashboard untuk menghindari melewati batas

## 10. Best Practices

1. **Jangan commit** secure bundle dan `.env` ke git
2. **Backup token** Client ID dan Secret di tempat aman
3. **Rotate token** secara berkala untuk keamanan
4. **Monitor usage** di dashboard AstraDB
5. **Setup alerts** untuk mendekati limit free tier

## 11. Sample Data

Setelah setup selesai, database akan memiliki:

- **13 produk** sample di berbagai kategori:
  - Main Course: 5 items
  - Beverages: 5 items
  - Snacks: 3 items
- **1 customer** default untuk walk-in orders

## 12. Query Examples

### Lihat semua products
```cql
SELECT * FROM sagawa_pos.products;
```

### Lihat products by category
```cql
SELECT * FROM sagawa_pos.products WHERE category = 'Main Course' ALLOW FILTERING;
```

### Count products
```cql
SELECT COUNT(*) FROM sagawa_pos.products;
```

### Insert new product
```cql
INSERT INTO sagawa_pos.products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Product Name', 'Description', 10000, 'Category', 100, '', true, toTimestamp(now()), toTimestamp(now()));
```

## 13. Next Steps

Setelah setup selesai:

1. ✅ Database AstraDB running
2. ✅ Tables sudah dibuat
3. ✅ Sample data sudah ada
4. ✅ Backend bisa connect ke database

Lanjut ke:
- Setup frontend Flutter
- Test API endpoints
- Mulai development fitur baru

## 14. Resources

- [AstraDB Documentation](https://docs.datastax.com/en/astra/home/astra.html)
- [CQL Reference](https://docs.datastax.com/en/cql-oss/3.x/cql/cql_reference/cqlReferenceTOC.html)
- [DataStax Go Driver](https://docs.datastax.com/en/developer/go-driver/latest/)

## 15. Support

Jika mengalami masalah:

1. Check [AstraDB Status Page](https://status.datastax.com/)
2. Baca dokumentasi di atas
3. Periksa logs backend untuk error messages
4. Contact DataStax support (untuk free tier, community support)
