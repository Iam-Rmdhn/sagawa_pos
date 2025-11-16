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

type OrderHandler struct {
	dbClient *config.AstraDBClient
}

func NewOrderHandler(dbClient *config.AstraDBClient) *OrderHandler {
	return &OrderHandler{dbClient: dbClient}
}

// GetAllOrders retrieves all orders
func (h *OrderHandler) GetAllOrders(c *fiber.Ctx) error {
	respData, err := h.dbClient.ExecuteQuery("GET", "/orders/rows", nil)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var response struct {
		Data []models.Order `json:"data"`
	}
	if err := json.Unmarshal(respData, &response); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

	return c.JSON(response.Data)
}

// GetOrder retrieves a single order by ID
func (h *OrderHandler) GetOrder(c *fiber.Ctx) error {
	id := c.Params("id")
	path := fmt.Sprintf("/orders/%s", id)
	
	respData, err := h.dbClient.ExecuteQuery("GET", path, nil)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Order not found"})
	}

	var response struct {
		Data models.Order `json:"data"`
	}
	if err := json.Unmarshal(respData, &response); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

	return c.JSON(response.Data)
}

// CreateOrder creates a new order
func (h *OrderHandler) CreateOrder(c *fiber.Ctx) error {
	var order models.Order
	if err := c.BodyParser(&order); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	order.ID = uuid.New().String()
	order.OrderNumber = fmt.Sprintf("ORD-%d", time.Now().Unix())
	order.CreatedAt = time.Now()
	order.UpdatedAt = time.Now()
	order.Status = "pending"

	// Calculate total
	var total float64
	for i := range order.Items {
		order.Items[i].Subtotal = float64(order.Items[i].Quantity) * order.Items[i].Price
		total += order.Items[i].Subtotal
	}
	order.TotalAmount = total

	body := map[string]interface{}{
		"id":             order.ID,
		"order_number":   order.OrderNumber,
		"customer_id":    order.CustomerID,
		"total_amount":   order.TotalAmount,
		"status":         order.Status,
		"payment_method": order.PaymentMethod,
		"created_at":     order.CreatedAt,
		"updated_at":     order.UpdatedAt,
	}

	if _, err := h.dbClient.ExecuteQuery("POST", "/orders", body); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(order)
}

// UpdateOrderStatus updates the status of an order
func (h *OrderHandler) UpdateOrderStatus(c *fiber.Ctx) error {
	id := c.Params("id")

	var reqBody struct {
		Status string `json:"status"`
	}
	if err := c.BodyParser(&reqBody); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	updatedAt := time.Now()
	body := map[string]interface{}{
		"status":     reqBody.Status,
		"updated_at": updatedAt,
	}

	path := fmt.Sprintf("/orders/%s", id)
	if _, err := h.dbClient.ExecuteQuery("PATCH", path, body); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Order status updated successfully", "status": reqBody.Status})
}
