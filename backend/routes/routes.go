package routes

import (
	"os"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/handlers"

	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(api fiber.Router, dbClient *config.AstraDBClient) {

	productHandler := handlers.NewProductHandler(dbClient)
	menuHandler := handlers.NewMenuHandler(dbClient)
	orderHandler := handlers.NewOrderHandler(dbClient)
	userHandler := handlers.NewUserHandler(dbClient)
	voucherHandler := handlers.NewVoucherHandler(dbClient)

	menuSyncWebSocketEnabled := os.Getenv("MENU_SYNC_WEBSOCKET_ENABLED") != "false"
	var menuSyncHub *handlers.MenuSyncWebSocketHub
	if menuSyncWebSocketEnabled {
		menuSyncHub = handlers.NewMenuSyncWebSocketHub(dbClient)
		menuSyncHub.Start()
	}

	products := api.Group("/products")
	products.Get("/", productHandler.GetAllProducts)
	products.Get("/:id", productHandler.GetProduct)
	products.Post("/", productHandler.CreateProduct)
	products.Put("/:id", productHandler.UpdateProduct)
	products.Delete("/:id", productHandler.DeleteProduct)

	menu := api.Group("/menu")
	menu.Get("/", menuHandler.GetAllMenu)
	menu.Get("/raw", menuHandler.GetRaw)
	menu.Get("/categories", menuHandler.GetCategories)
	menu.Get("/sync", menuHandler.GetMenuSync)
	if menuSyncWebSocketEnabled {
		menu.Use("/sync/ws", func(c *fiber.Ctx) error {
			if websocket.IsWebSocketUpgrade(c) {
				return c.Next()
			}
			return fiber.ErrUpgradeRequired
		})
		menu.Get("/sync/ws", websocket.New(menuSyncHub.HandleConnection))
	}
	menu.Post("/refresh-cache", menuHandler.RefreshMenuCache)
	menu.Get("/:id", menuHandler.GetMenu)

	kasir := api.Group("/kasir")
	kasir.Get("/", userHandler.GetAllKasir)
	kasir.Get("/:id", userHandler.GetKasir)
	kasir.Post("/login", userHandler.Login)

	kasir.Put("/:id/profile", userHandler.UpdateProfile)

	kasir.Put("/:id/password", userHandler.SetPassword)

	orders := api.Group("/orders")
	orders.Get("/", orderHandler.GetAllOrders)
	orders.Get("/:id", orderHandler.GetOrder)
	orders.Post("/", orderHandler.CreateOrder)
	orders.Patch("/:id/status", orderHandler.UpdateOrderStatus)
	orders.Post("/transaction", orderHandler.SaveTransaction)

	transactions := api.Group("/transactions")
	transactions.Get("/outlet/:outlet_id", orderHandler.GetTransactionsByOutlet)
	transactions.Get("/outlet/:outlet_id/range", orderHandler.GetTransactionsByOutletAndDateRange)
	transactions.Get("/outlet/:outlet_id/recap", orderHandler.GetYearlyRecap)
	transactions.Get("/admin/all", orderHandler.GetAllTransactionsForAdmin)

	vouchers := api.Group("/vouchers")
	vouchers.Post("/verify", voucherHandler.VerifyVoucher)
	vouchers.Post("/use", voucherHandler.UseVoucher)
	vouchers.Get("/check", voucherHandler.GetVoucherByCode)
}
