package main

import (
	"log"
	"os"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/routes"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/joho/godotenv"
)

func main() {

	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	dbClient, err := config.ConnectAstraDB()
	if err != nil {
		log.Fatalf("Failed to connect to AstraDB: %v", err)
	}
	defer dbClient.Close()

	log.Println("Successfully connected to AstraDB")

	app := fiber.New(fiber.Config{
		AppName: "Sagawa POS API v1.0.0",
	})

	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: os.Getenv("ALLOWED_ORIGINS"),
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",
	}))

	app.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"app":     "Sagawa POS API",
			"version": "v1.0.0",
			"status":  "running",
			"docs":    "/api/v1/docs (jika ada)",
			"health":  "/health",
		})
	})

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"message": "Sagawa POS API is running",
		})
	})

	api := app.Group("/api/v1")
	routes.SetupRoutes(api, dbClient)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
