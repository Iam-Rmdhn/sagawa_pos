package handlers

import (
	"sagawa_pos_backend/models"
	"time"

	"github.com/gocql/gocql"
	"github.com/gofiber/fiber/v2"
)

type ProductHandler struct {
	session *gocql.Session
}

func NewProductHandler(session *gocql.Session) *ProductHandler {
	return &ProductHandler{session: session}
}

// GetAllProducts retrieves all products
func (h *ProductHandler) GetAllProducts(c *fiber.Ctx) error {
	var products []models.Product

	iter := h.session.Query(`SELECT id, name, description, price, category, stock, image_url, is_active, created_at, updated_at FROM products`).Iter()

	var product models.Product
	for iter.Scan(&product.ID, &product.Name, &product.Description, &product.Price, &product.Category, &product.Stock, &product.ImageURL, &product.IsActive, &product.CreatedAt, &product.UpdatedAt) {
		products = append(products, product)
		product = models.Product{} // Reset for next iteration
	}

	if err := iter.Close(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(products)
}

// GetProduct retrieves a single product by ID
func (h *ProductHandler) GetProduct(c *fiber.Ctx) error {
	id := c.Params("id")
	productID, err := gocql.ParseUUID(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid product ID"})
	}

	var product models.Product
	if err := h.session.Query(`SELECT id, name, description, price, category, stock, image_url, is_active, created_at, updated_at FROM products WHERE id = ?`, productID).
		Scan(&product.ID, &product.Name, &product.Description, &product.Price, &product.Category, &product.Stock, &product.ImageURL, &product.IsActive, &product.CreatedAt, &product.UpdatedAt); err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Product not found"})
	}

	return c.JSON(product)
}

// CreateProduct creates a new product
func (h *ProductHandler) CreateProduct(c *fiber.Ctx) error {
	var product models.Product
	if err := c.BodyParser(&product); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	product.ID = gocql.TimeUUID()
	product.CreatedAt = time.Now()
	product.UpdatedAt = time.Now()
	product.IsActive = true

	if err := h.session.Query(`INSERT INTO products (id, name, description, price, category, stock, image_url, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		product.ID, product.Name, product.Description, product.Price, product.Category, product.Stock, product.ImageURL, product.IsActive, product.CreatedAt, product.UpdatedAt).Exec(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(product)
}

// UpdateProduct updates an existing product
func (h *ProductHandler) UpdateProduct(c *fiber.Ctx) error {
	id := c.Params("id")
	productID, err := gocql.ParseUUID(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid product ID"})
	}

	var product models.Product
	if err := c.BodyParser(&product); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	product.ID = productID
	product.UpdatedAt = time.Now()

	if err := h.session.Query(`UPDATE products SET name = ?, description = ?, price = ?, category = ?, stock = ?, image_url = ?, is_active = ?, updated_at = ? WHERE id = ?`,
		product.Name, product.Description, product.Price, product.Category, product.Stock, product.ImageURL, product.IsActive, product.UpdatedAt, productID).Exec(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(product)
}

// DeleteProduct deletes a product
func (h *ProductHandler) DeleteProduct(c *fiber.Ctx) error {
	id := c.Params("id")
	productID, err := gocql.ParseUUID(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid product ID"})
	}

	if err := h.session.Query(`DELETE FROM products WHERE id = ?`, productID).Exec(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Product deleted successfully"})
}
