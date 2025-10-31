package models

import (
	"time"

	"github.com/gocql/gocql"
)

// Customer represents a customer in the POS system
type Customer struct {
	ID        gocql.UUID `json:"id"`
	Name      string     `json:"name"`
	Email     string     `json:"email"`
	Phone     string     `json:"phone"`
	Address   string     `json:"address"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
}

// CreateCustomerTable creates the customers table in AstraDB
const CreateCustomerTable = `
CREATE TABLE IF NOT EXISTS customers (
	id UUID PRIMARY KEY,
	name TEXT,
	email TEXT,
	phone TEXT,
	address TEXT,
	created_at TIMESTAMP,
	updated_at TIMESTAMP
)
`
