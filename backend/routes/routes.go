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
	menuHandler := handlers.NewMenuHandler(dbClient)
	orderHandler := handlers.NewOrderHandler(dbClient)
	userHandler := handlers.NewUserHandler(dbClient)

	// Product routes
	products := api.Group("/products")
	products.Get("/", productHandler.GetAllProducts)
	products.Get("/:id", productHandler.GetProduct)
	products.Post("/", productHandler.CreateProduct)
	products.Put("/:id", productHandler.UpdateProduct)
	products.Delete("/:id", productHandler.DeleteProduct)

	// Menu routes (menu_makanan collection)
	menu := api.Group("/menu")
	menu.Get("/", menuHandler.GetAllMenu)
	menu.Get("/raw", menuHandler.GetRaw)
	menu.Get("/:id", menuHandler.GetMenu)

	// Kasir (users) routes
	kasir := api.Group("/kasir")
	kasir.Get("/", userHandler.GetAllKasir)
	kasir.Get("/:id", userHandler.GetKasir)
	kasir.Post("/login", userHandler.Login)
	// Dev-only: set password when DEV_ALLOW_PASSWORD_UPDATE is set
	kasir.Put("/:id/password", userHandler.SetPassword)

	// Order routes
	orders := api.Group("/orders")
	orders.Get("/", orderHandler.GetAllOrders)
	orders.Get("/:id", orderHandler.GetOrder)
	orders.Post("/", orderHandler.CreateOrder)
	orders.Patch("/:id/status", orderHandler.UpdateOrderStatus)
}
