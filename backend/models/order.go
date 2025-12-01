package models

import (
	"time"
)

// Order represents an order in the POS system
type Order struct {
	ID            string      `json:"id"`
	OrderNumber   string      `json:"order_number"`
	CustomerID    string      `json:"customer_id"`
	Items         []OrderItem `json:"items"`
	TotalAmount   float64     `json:"total_amount"`
	Status        string      `json:"status"` // pending, completed, cancelled
	PaymentMethod string      `json:"payment_method"`
	CreatedAt     time.Time   `json:"created_at"`
	UpdatedAt     time.Time   `json:"updated_at"`
}

// OrderItem represents an item in an order
type OrderItem struct {
	ProductID string  `json:"product_id"`
	Name      string  `json:"name"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
	Subtotal  float64 `json:"subtotal"`
}

// TransactionItem represents an item in a transaction
type TransactionItem struct {
	MenuName string  `json:"menu_name"`
	Qty      int     `json:"qty"`
	Price    float64 `json:"price"`
	Subtotal float64 `json:"subtotal"`
}

// Transaction represents a completed transaction from POS
type Transaction struct {
	TrxID      string            `json:"trx_id"`
	OutletID   string            `json:"outlet_id"`
	OutletName string            `json:"outlet_name"`
	Items      []TransactionItem `json:"items"`
	Cashier    string            `json:"cashier"`
	Customer   string            `json:"customer"`
	Note       string            `json:"note,omitempty"`
	Type       string            `json:"type"`   // dine_in / take_away
	Method     string            `json:"method"` // cash / qris
	Nominal    float64           `json:"nominal"`
	Subtotal   float64           `json:"subtotal"`
	Tax        float64           `json:"tax"`
	Total      float64           `json:"total"`
	Qris       float64           `json:"qris"`
	Changes    float64           `json:"changes"`
	CreatedAt  time.Time         `json:"created_at"`
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

// CreateTransactionTable creates the transactions table in AstraDB
const CreateTransactionTable = `
CREATE TABLE IF NOT EXISTS transactions (
	trx_id TEXT PRIMARY KEY,
	items LIST<FROZEN<transaction_item>>,
	cashier TEXT,
	customer TEXT,
	note TEXT,
	type TEXT,
	method TEXT,
	nominal DOUBLE,
	subtotal DOUBLE,
	tax DOUBLE,
	total DOUBLE,
	qris DOUBLE,
	changes DOUBLE,
	created_at TIMESTAMP
)
`

// CreateTransactionItemType creates the transaction_item user-defined type
const CreateTransactionItemType = `
CREATE TYPE IF NOT EXISTS transaction_item (
	menu_name TEXT,
	qty INT,
	price DOUBLE,
	subtotal DOUBLE
)
`
