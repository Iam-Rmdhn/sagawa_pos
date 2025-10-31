package models

import (
	"time"

	"github.com/gocql/gocql"
)

// Order represents an order in the POS system
type Order struct {
	ID            gocql.UUID  `json:"id"`
	OrderNumber   string      `json:"order_number"`
	CustomerID    gocql.UUID  `json:"customer_id"`
	Items         []OrderItem `json:"items"`
	TotalAmount   float64     `json:"total_amount"`
	Status        string      `json:"status"` // pending, completed, cancelled
	PaymentMethod string      `json:"payment_method"`
	CreatedAt     time.Time   `json:"created_at"`
	UpdatedAt     time.Time   `json:"updated_at"`
}

// OrderItem represents an item in an order
type OrderItem struct {
	ProductID gocql.UUID `json:"product_id"`
	Name      string     `json:"name"`
	Quantity  int        `json:"quantity"`
	Price     float64    `json:"price"`
	Subtotal  float64    `json:"subtotal"`
}

// CreateOrderTable creates the orders table in AstraDB
const CreateOrderTable = `
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
)
`

// CreateOrderItemType creates the order_item user-defined type
const CreateOrderItemType = `
CREATE TYPE IF NOT EXISTS order_item (
	product_id UUID,
	name TEXT,
	quantity INT,
	price DOUBLE,
	subtotal DOUBLE
)
`
