package models

import (
	"time"

	"github.com/gocql/gocql"
)

// Product represents a product in the POS system
type Product struct {
	ID          gocql.UUID `json:"id"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	Price       float64    `json:"price"`
	Category    string     `json:"category"`
	Stock       int        `json:"stock"`
	ImageURL    string     `json:"image_url"`
	IsActive    bool       `json:"is_active"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

// CreateProductTable creates the products table in AstraDB
const CreateProductTable = `
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
)
`
