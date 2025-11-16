package routes

import (
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/handlers"

	"github.com/gofiber/fiber/v2"
)

// SetupRoutes configures all API routes
func SetupRoutes(api fiber.Router, dbClient *config.AstraDBClient) {
	// Initialize handlers
	productHandler := handlers.NewProductHandler(dbClient)
	orderHandler := handlers.NewOrderHandler(dbClient)

	// Product routes
	products := api.Group("/products")
	products.Get("/", productHandler.GetAllProducts)
	products.Get("/:id", productHandler.GetProduct)
	products.Post("/", productHandler.CreateProduct)
	products.Put("/:id", productHandler.UpdateProduct)
	products.Delete("/:id", productHandler.DeleteProduct)

	// Order routes
	orders := api.Group("/orders")
	orders.Get("/", orderHandler.GetAllOrders)
	orders.Get("/:id", orderHandler.GetOrder)
	orders.Post("/", orderHandler.CreateOrder)
	orders.Patch("/:id/status", orderHandler.UpdateOrderStatus)
}
