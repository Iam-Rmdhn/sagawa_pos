package models

import "time"

// Menu represents an item in the menu_makanan collection
type Menu struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Kemitraan   string    `json:"kemitraan"`
	Price       float64   `json:"price"`
	SubBrand    string    `json:"subBrand"`
	CreatedAt   time.Time `json:"createdAt"`
	ImageURL    string    `json:"imageUrl"`
	ImageID     string    `json:"imageId"`
	ImageData   string    `json:"imageData"`
}
