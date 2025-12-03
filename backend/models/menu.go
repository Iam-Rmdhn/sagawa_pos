package models

import "time"

// Menu represents an item in the menu_makanan collection
type Menu struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Kemitraan   string    `json:"kemitraan"`
	SubBrand    string    `json:"subBrand"`
	Kategori    string    `json:"kategori"`
	Price       float64   `json:"price"`
	CreatedAt   time.Time `json:"createdAt"`
	ImageURL    string    `json:"imageUrl"`
	ImageID     string    `json:"imageId"`
	ImageData   string    `json:"imageData"`
}
