# API Documentation - Sagawa POS

Base URL: `http://localhost:8080/api/v1`

## Endpoints

### Health Check

#### GET /health
Check if the API is running.

**Response:**
```json
{
  "status": "ok",
  "message": "Sagawa POS API is running"
}
```

---

## Products

### GET /api/v1/products
Get all products.

**Response:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Nasi Goreng Spesial",
    "description": "Nasi goreng dengan telur dan ayam",
    "price": 25000,
    "category": "Main Course",
    "stock": 50,
    "image_url": "",
    "is_active": true,
    "created_at": "2025-10-31T10:00:00Z",
    "updated_at": "2025-10-31T10:00:00Z"
  }
]
```

---

### GET /api/v1/products/:id
Get a single product by ID.

**Parameters:**
- `id` (path) - Product UUID

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Nasi Goreng Spesial",
  "description": "Nasi goreng dengan telur dan ayam",
  "price": 25000,
  "category": "Main Course",
  "stock": 50,
  "image_url": "",
  "is_active": true,
  "created_at": "2025-10-31T10:00:00Z",
  "updated_at": "2025-10-31T10:00:00Z"
}
```

**Error Response:**
- `400` - Invalid product ID
- `404` - Product not found

---

### POST /api/v1/products
Create a new product.

**Request Body:**
```json
{
  "name": "Ayam Goreng",
  "description": "Ayam goreng crispy",
  "price": 30000,
  "category": "Main Course",
  "stock": 30,
  "image_url": "",
  "is_active": true
}
```

**Response:** (201 Created)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "name": "Ayam Goreng",
  "description": "Ayam goreng crispy",
  "price": 30000,
  "category": "Main Course",
  "stock": 30,
  "image_url": "",
  "is_active": true,
  "created_at": "2025-10-31T11:00:00Z",
  "updated_at": "2025-10-31T11:00:00Z"
}
```

**Error Response:**
- `400` - Invalid request body

---

### PUT /api/v1/products/:id
Update an existing product.

**Parameters:**
- `id` (path) - Product UUID

**Request Body:**
```json
{
  "name": "Ayam Goreng Spesial",
  "description": "Ayam goreng crispy dengan bumbu spesial",
  "price": 32000,
  "category": "Main Course",
  "stock": 25,
  "image_url": "",
  "is_active": true
}
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "name": "Ayam Goreng Spesial",
  "description": "Ayam goreng crispy dengan bumbu spesial",
  "price": 32000,
  "category": "Main Course",
  "stock": 25,
  "image_url": "",
  "is_active": true,
  "created_at": "2025-10-31T11:00:00Z",
  "updated_at": "2025-10-31T12:00:00Z"
}
```

**Error Response:**
- `400` - Invalid product ID or request body
- `500` - Update failed

---

### DELETE /api/v1/products/:id
Delete a product.

**Parameters:**
- `id` (path) - Product UUID

**Response:**
```json
{
  "message": "Product deleted successfully"
}
```

**Error Response:**
- `400` - Invalid product ID
- `500` - Delete failed

---

## Orders

### GET /api/v1/orders
Get all orders.

**Response:**
```json
[
  {
    "id": "650e8400-e29b-41d4-a716-446655440000",
    "order_number": "ORD-1698744000",
    "customer_id": "00000000-0000-0000-0000-000000000000",
    "items": [],
    "total_amount": 75000,
    "status": "completed",
    "payment_method": "Cash",
    "created_at": "2025-10-31T10:00:00Z",
    "updated_at": "2025-10-31T10:15:00Z"
  }
]
```

---

### GET /api/v1/orders/:id
Get a single order by ID.

**Parameters:**
- `id` (path) - Order UUID

**Response:**
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440000",
  "order_number": "ORD-1698744000",
  "customer_id": "00000000-0000-0000-0000-000000000000",
  "items": [
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Nasi Goreng Spesial",
      "quantity": 2,
      "price": 25000,
      "subtotal": 50000
    },
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Es Teh Manis",
      "quantity": 5,
      "price": 5000,
      "subtotal": 25000
    }
  ],
  "total_amount": 75000,
  "status": "completed",
  "payment_method": "Cash",
  "created_at": "2025-10-31T10:00:00Z",
  "updated_at": "2025-10-31T10:15:00Z"
}
```

**Error Response:**
- `400` - Invalid order ID
- `404` - Order not found

---

### POST /api/v1/orders
Create a new order.

**Request Body:**
```json
{
  "customer_id": "00000000-0000-0000-0000-000000000000",
  "items": [
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Nasi Goreng Spesial",
      "quantity": 2,
      "price": 25000,
      "subtotal": 50000
    },
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Es Teh Manis",
      "quantity": 5,
      "price": 5000,
      "subtotal": 25000
    }
  ],
  "payment_method": "Cash"
}
```

**Response:** (201 Created)
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440001",
  "order_number": "ORD-1698744100",
  "customer_id": "00000000-0000-0000-0000-000000000000",
  "items": [
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Nasi Goreng Spesial",
      "quantity": 2,
      "price": 25000,
      "subtotal": 50000
    },
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Es Teh Manis",
      "quantity": 5,
      "price": 5000,
      "subtotal": 25000
    }
  ],
  "total_amount": 75000,
  "status": "pending",
  "payment_method": "Cash",
  "created_at": "2025-10-31T11:00:00Z",
  "updated_at": "2025-10-31T11:00:00Z"
}
```

**Notes:**
- Order number is auto-generated
- Status is automatically set to "pending"
- Total amount is calculated from items

**Error Response:**
- `400` - Invalid request body
- `500` - Order creation failed

---

### PATCH /api/v1/orders/:id/status
Update order status.

**Parameters:**
- `id` (path) - Order UUID

**Request Body:**
```json
{
  "status": "completed"
}
```

**Valid status values:**
- `pending` - Order is waiting to be processed
- `completed` - Order has been completed
- `cancelled` - Order has been cancelled

**Response:**
```json
{
  "message": "Order status updated successfully",
  "status": "completed"
}
```

**Error Response:**
- `400` - Invalid order ID or request body
- `500` - Update failed

---

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "error": "Invalid request body"
}
```

### 404 Not Found
```json
{
  "error": "Product not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Database connection failed"
}
```

---

## Testing with cURL

### Create a product
```bash
curl -X POST http://localhost:8080/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "This is a test product",
    "price": 15000,
    "category": "Test",
    "stock": 100,
    "image_url": "",
    "is_active": true
  }'
```

### Get all products
```bash
curl http://localhost:8080/api/v1/products
```

### Create an order
```bash
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "00000000-0000-0000-0000-000000000000",
    "items": [
      {
        "product_id": "PRODUCT_UUID_HERE",
        "name": "Nasi Goreng",
        "quantity": 2,
        "price": 25000,
        "subtotal": 50000
      }
    ],
    "payment_method": "Cash"
  }'
```

### Update order status
```bash
curl -X PATCH http://localhost:8080/api/v1/orders/ORDER_UUID_HERE/status \
  -H "Content-Type: application/json" \
  -d '{
    "status": "completed"
  }'
```

---

## Rate Limiting

Currently, there is no rate limiting implemented. This should be added for production use.

## Authentication

Currently, there is no authentication implemented. All endpoints are publicly accessible. This should be added for production use.

## CORS

CORS is enabled for origins specified in the `ALLOWED_ORIGINS` environment variable.
