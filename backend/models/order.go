package models

import (
	"time"
)

type Order struct {
	ID            string      `json:"id"`
	OrderNumber   string      `json:"order_number"`
	CustomerID    string      `json:"customer_id"`
	Items         []OrderItem `json:"items"`
	TotalAmount   float64     `json:"total_amount"`
	Status        string      `json:"status"`
	PaymentMethod string      `json:"payment_method"`
	CreatedAt     time.Time   `json:"created_at"`
	UpdatedAt     time.Time   `json:"updated_at"`
}

type OrderItem struct {
	ProductID string  `json:"product_id"`
	Name      string  `json:"name"`
	Quantity  int     `json:"quantity"`
	Price     float64 `json:"price"`
	Subtotal  float64 `json:"subtotal"`
}

type TransactionItem struct {
	MenuName string  `json:"menu_name"`
	Qty      int     `json:"qty"`
	Price    float64 `json:"price"`
	Subtotal float64 `json:"subtotal"`
}

type Transaction struct {
	TrxID                   string            `json:"trx_id"`
	OutletID                string            `json:"outlet_id"`
	OutletName              string            `json:"outlet_name"`
	Items                   []TransactionItem `json:"items"`
	Cashier                 string            `json:"cashier"`
	Customer                string            `json:"customer"`
	Note                    string            `json:"note,omitempty"`
	Type                    string            `json:"type"`
	Method                  string            `json:"method"`
	Nominal                 float64           `json:"nominal"`
	Subtotal                float64           `json:"subtotal"`
	Tax                     float64           `json:"tax"`
	Total                   float64           `json:"total"`
	Qris                    float64           `json:"qris"`
	Changes                 float64           `json:"changes"`
	DiscountPercent         *int              `json:"discount_percent,omitempty"`
	DiscountAmount          *float64          `json:"discount_amount,omitempty"`
	VoucherCode             *string           `json:"voucher_code,omitempty"`
	VoucherAmount           *float64          `json:"voucher_amount,omitempty"`
	AdditionalPayment       *float64          `json:"additional_payment,omitempty"`
	AdditionalPaymentMethod *string           `json:"additional_payment_method,omitempty"`
	CreatedAt               time.Time         `json:"created_at"`
}

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

const CreateOrderItemType = `
CREATE TYPE IF NOT EXISTS order_item (
	product_id UUID,
	name TEXT,
	quantity INT,
	price DOUBLE,
	subtotal DOUBLE
)
`

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

const CreateTransactionItemType = `
CREATE TYPE IF NOT EXISTS transaction_item (
	menu_name TEXT,
	qty INT,
	price DOUBLE,
	subtotal DOUBLE
)
`
