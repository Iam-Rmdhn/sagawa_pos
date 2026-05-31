package models

import "time"

type Menu struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	Kemitraan    string    `json:"kemitraan"`
	SubBrand     string    `json:"subBrand"`
	Kategori     string    `json:"kategori"`
	Price        float64   `json:"price"`
	Stock        int       `json:"stock"`
	IsActive     bool      `json:"is_active"`
	IsEnabled    bool      `json:"isEnabled"`
	IsBestSeller bool      `json:"isBestSeller"`
	CreatedAt    time.Time `json:"createdAt"`
	ImageURL     string    `json:"imageUrl"`
	ImageID      string    `json:"imageId"`
	ImageData    string    `json:"imageData"`
}
