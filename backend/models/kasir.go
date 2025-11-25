package models

import "time"

// Kasir represents a cashier (kasir_pos collection)
type Kasir struct {
    ID               string    `json:"id"`
    Username         string    `json:"username"`
    Kemitraan        string    `json:"kemitraan"`
    Outlet           string    `json:"outlet"`
    Password         string    `json:"password"`
    Role             string    `json:"role"`
    CreatedAt        time.Time `json:"createdAt"`
    ProfilePhoto     string    `json:"profilePhoto"`
    SubBrand         string    `json:"subBrand"`
    ProfilePhotoData string    `json:"profilePhotoData"`
    ProfilePhotoId   string    `json:"profilePhotoId"`
    ProfilePhotoUrl  string    `json:"profilePhotoUrl"`
}
