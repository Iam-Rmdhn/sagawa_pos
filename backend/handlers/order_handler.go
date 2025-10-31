package handlers

import (
	"fmt"
	"sagawa_pos_backend/models"
	"time"

	"github.com/gocql/gocql"
	"github.com/gofiber/fiber/v2"
)

type OrderHandler struct {
	session *gocql.Session
}

func NewOrderHandler(session *gocql.Session) *OrderHandler {
	return &OrderHandler{session: session}
}

// GetAllOrders retrieves all orders
func (h *OrderHandler) GetAllOrders(c *fiber.Ctx) error {
	var orders []models.Order

	iter := h.session.Query(`SELECT id, order_number, customer_id, total_amount, status, payment_method, created_at, updated_at FROM orders`).Iter()

	var order models.Order
	for iter.Scan(&order.ID, &order.OrderNumber, &order.CustomerID, &order.TotalAmount, &order.Status, &order.PaymentMethod, &order.CreatedAt, &order.UpdatedAt) {
		orders = append(orders, order)
		order = models.Order{} // Reset for next iteration
	}

	if err := iter.Close(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(orders)
}

// GetOrder retrieves a single order by ID
func (h *OrderHandler) GetOrder(c *fiber.Ctx) error {
	id := c.Params("id")
	orderID, err := gocql.ParseUUID(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid order ID"})
	}

	var order models.Order
	if err := h.session.Query(`SELECT id, order_number, customer_id, total_amount, status, payment_method, created_at, updated_at FROM orders WHERE id = ?`, orderID).
		Scan(&order.ID, &order.OrderNumber, &order.CustomerID, &order.TotalAmount, &order.Status, &order.PaymentMethod, &order.CreatedAt, &order.UpdatedAt); err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Order not found"})
	}

	return c.JSON(order)
}

// CreateOrder creates a new order
func (h *OrderHandler) CreateOrder(c *fiber.Ctx) error {
	var order models.Order
	if err := c.BodyParser(&order); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	order.ID = gocql.TimeUUID()
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

	if err := h.session.Query(`INSERT INTO orders (id, order_number, customer_id, total_amount, status, payment_method, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		order.ID, order.OrderNumber, order.CustomerID, order.TotalAmount, order.Status, order.PaymentMethod, order.CreatedAt, order.UpdatedAt).Exec(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(order)
}

// UpdateOrderStatus updates the status of an order
func (h *OrderHandler) UpdateOrderStatus(c *fiber.Ctx) error {
	id := c.Params("id")
	orderID, err := gocql.ParseUUID(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid order ID"})
	}

	var body struct {
		Status string `json:"status"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	updatedAt := time.Now()
	if err := h.session.Query(`UPDATE orders SET status = ?, updated_at = ? WHERE id = ?`,
		body.Status, updatedAt, orderID).Exec(); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Order status updated successfully", "status": body.Status})
}
