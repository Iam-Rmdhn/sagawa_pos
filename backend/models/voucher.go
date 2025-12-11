package models

import "time"

// Voucher represents a voucher in the system
type Voucher struct {
	ID           string    `json:"_id,omitempty"`
	CodeVoucher  string    `json:"code_voucher"`
	Nominal      int       `json:"nominal"`
	Used         bool      `json:"used"`
	CreatedAt    time.Time `json:"createdAt"`
	UsedAt       time.Time `json:"usedAt,omitempty"`
	CreatedBy    string    `json:"createdBy"`
	RedeemedBy   string    `json:"redeemedBy,omitempty"`
}

// VerifyVoucherRequest represents the request body for voucher verification (check only)
type VerifyVoucherRequest struct {
	CodeVoucher string `json:"code_voucher"`
}

// VerifyVoucherResponse represents the response for voucher verification (check only)
type VerifyVoucherResponse struct {
	Success     bool   `json:"success"`
	Message     string `json:"message"`
	CodeVoucher string `json:"code_voucher,omitempty"`
	Nominal     int    `json:"nominal,omitempty"`
}

// UseVoucherRequest represents the request body for using a voucher
type UseVoucherRequest struct {
	CodeVoucher string `json:"code_voucher"`
	RedeemedBy  string `json:"redeemed_by,omitempty"`
}

// UseVoucherResponse represents the response for using a voucher
type UseVoucherResponse struct {
	Success     bool   `json:"success"`
	Message     string `json:"message"`
	CodeVoucher string `json:"code_voucher,omitempty"`
	Nominal     int    `json:"nominal,omitempty"`
}
