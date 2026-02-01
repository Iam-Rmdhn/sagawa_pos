package models

import "time"

type Voucher struct {
	ID          string    `json:"_id,omitempty"`
	CodeVoucher string    `json:"code_voucher"`
	Nominal     int       `json:"nominal"`
	Used        bool      `json:"used"`
	CreatedAt   time.Time `json:"createdAt"`
	UsedAt      time.Time `json:"usedAt,omitempty"`
	CreatedBy   string    `json:"createdBy"`
	RedeemedBy  string    `json:"redeemedBy,omitempty"`
}

type VerifyVoucherRequest struct {
	CodeVoucher string `json:"code_voucher"`
}

type VerifyVoucherResponse struct {
	Success     bool   `json:"success"`
	Message     string `json:"message"`
	CodeVoucher string `json:"code_voucher,omitempty"`
	Nominal     int    `json:"nominal,omitempty"`
}

type UseVoucherRequest struct {
	CodeVoucher string `json:"code_voucher"`
	RedeemedBy  string `json:"redeemed_by,omitempty"`
}

type UseVoucherResponse struct {
	Success     bool   `json:"success"`
	Message     string `json:"message"`
	CodeVoucher string `json:"code_voucher,omitempty"`
	Nominal     int    `json:"nominal,omitempty"`
}
