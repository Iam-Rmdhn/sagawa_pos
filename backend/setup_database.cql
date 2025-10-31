-- AstraDB Setup Script untuk Sagawa POS
-- Jalankan script ini di CQL Console AstraDB

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

-- Insert sample products untuk testing
INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Nasi Goreng Spesial', 'Nasi goreng dengan telur dan ayam', 25000, 'Main Course', 50, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Mie Goreng Spesial', 'Mie goreng dengan sayuran', 20000, 'Main Course', 50, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Ayam Goreng Crispy', 'Ayam goreng tepung crispy', 30000, 'Main Course', 30, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Soto Ayam', 'Soto ayam dengan nasi', 22000, 'Main Course', 40, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Bakso Spesial', 'Bakso sapi dengan mie', 18000, 'Main Course', 60, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Es Teh Manis', 'Es teh manis segar', 5000, 'Beverages', 100, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Es Jeruk', 'Es jeruk segar', 8000, 'Beverages', 100, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Jus Alpukat', 'Jus alpukat segar', 12000, 'Beverages', 80, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Kopi Hitam', 'Kopi hitam panas', 10000, 'Beverages', 100, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Teh Tarik', 'Teh tarik panas', 8000, 'Beverages', 100, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Pisang Goreng', 'Pisang goreng dengan meses', 10000, 'Snacks', 50, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Tahu Isi', 'Tahu isi sayuran', 8000, 'Snacks', 60, '', true, toTimestamp(now()), toTimestamp(now()));

INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at)
VALUES (uuid(), 'Cireng', 'Cireng isi bumbu', 7000, 'Snacks', 70, '', true, toTimestamp(now()), toTimestamp(now()));

-- Insert default customer
INSERT INTO customers (id, name, email, phone, address, created_at, updated_at)
VALUES (00000000-0000-0000-0000-000000000000, 'Walk-in Customer', '', '', '', toTimestamp(now()), toTimestamp(now()));

-- Verify data
SELECT COUNT(*) as product_count FROM products;
SELECT COUNT(*) as customer_count FROM customers;
