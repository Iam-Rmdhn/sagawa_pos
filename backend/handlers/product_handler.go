package handlers

import (
	"encoding/json"
	"fmt"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/models"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type ProductHandler struct {
	dbClient *config.AstraDBClient
}

func NewProductHandler(dbClient *config.AstraDBClient) *ProductHandler {
	return &ProductHandler{dbClient: dbClient}
}

// GetAllProducts retrieves all products
func (h *ProductHandler) GetAllProducts(c *fiber.Ctx) error {
	respData, err := h.dbClient.ExecuteQuery("GET", "/products/rows", nil)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var response struct {
		Data []models.Product `json:"data"`
	}
	if err := json.Unmarshal(respData, &response); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

	return c.JSON(response.Data)
}

// GetProduct retrieves a single product by ID
func (h *ProductHandler) GetProduct(c *fiber.Ctx) error {
	id := c.Params("id")
	path := fmt.Sprintf("/products/%s", id)
	
	respData, err := h.dbClient.ExecuteQuery("GET", path, nil)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Product not found"})
	}

	var response struct {
		Data models.Product `json:"data"`
	}
	if err := json.Unmarshal(respData, &response); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

	return c.JSON(response.Data)
}

// CreateProduct creates a new product
func (h *ProductHandler) CreateProduct(c *fiber.Ctx) error {
	var product models.Product
	if err := c.BodyParser(&product); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	product.ID = uuid.New().String()
	product.CreatedAt = time.Now()
	product.UpdatedAt = time.Now()
	product.IsActive = true

	body := map[string]interface{}{
		"id":          product.ID,
		"name":        product.Name,
		"description": product.Description,
		"price":       product.Price,
		"category":    product.Category,
		"stock":       product.Stock,
		"image_url":   product.ImageURL,
		"is_active":   product.IsActive,
		"created_at":  product.CreatedAt,
		"updated_at":  product.UpdatedAt,
	}

	if _, err := h.dbClient.ExecuteQuery("POST", "/products", body); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(product)
}

// UpdateProduct updates an existing product
func (h *ProductHandler) UpdateProduct(c *fiber.Ctx) error {
	id := c.Params("id")

	var product models.Product
	if err := c.BodyParser(&product); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	product.ID = id
	product.UpdatedAt = time.Now()

	body := map[string]interface{}{
		"name":        product.Name,
		"description": product.Description,
		"price":       product.Price,
		"category":    product.Category,
		"stock":       product.Stock,
		"image_url":   product.ImageURL,
		"is_active":   product.IsActive,
		"updated_at":  product.UpdatedAt,
	}

	path := fmt.Sprintf("/products/%s", id)
	if _, err := h.dbClient.ExecuteQuery("PUT", path, body); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(product)
}

// DeleteProduct deletes a product
func (h *ProductHandler) DeleteProduct(c *fiber.Ctx) error {
	id := c.Params("id")
	path := fmt.Sprintf("/products/%s", id)

	if _, err := h.dbClient.ExecuteQuery("DELETE", path, nil); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Product deleted successfully"})
}
