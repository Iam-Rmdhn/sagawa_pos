package handlers

import (
	"encoding/json"
	"fmt"
	"os"
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

// SaveTransaction saves a completed transaction to the database
func (h *OrderHandler) SaveTransaction(c *fiber.Ctx) error {
	var transaction models.Transaction
	if err := c.BodyParser(&transaction); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	// Validate required fields
	if transaction.TrxID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Transaction ID is required"})
	}
	if transaction.Cashier == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Cashier is required"})
	}
	if transaction.Type == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Order type is required"})
	}
	if transaction.Method == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Payment method is required"})
	}

	// Set created_at timestamp
	createdAt := time.Now().Format(time.RFC3339)

	// Prepare document for Data API (Collection)
	document := map[string]interface{}{
		"_id":         transaction.TrxID, // Use trx_id as document ID
		"trx_id":      transaction.TrxID,
		"outlet_id":   transaction.OutletID,
		"outlet_name": transaction.OutletName,
		"items":       transaction.Items,
		"cashier":     transaction.Cashier,
		"customer":    transaction.Customer,
		"note":        transaction.Note,
		"type":        transaction.Type,
		"method":      transaction.Method,
		"nominal":     transaction.Nominal,
		"subtotal":    transaction.Subtotal,
		"tax":         transaction.Tax,
		"total":       transaction.Total,
		"qris":        transaction.Qris,
		"changes":     transaction.Changes,
		"created_at":  createdAt,
		"status":      "completed",
	}

	// Always save to local file as backup
	if err := saveTransactionToFile(document); err != nil {
		fmt.Printf("Warning: Failed to save transaction to local file: %v\n", err)
	}

	// Save to AstraDB using Data API (Collection: order)
	respBody, dbErr := h.dbClient.InsertDocument("order", document)
	if dbErr != nil {
		fmt.Printf("Warning: Failed to save to AstraDB: %v\n", dbErr)
		// Still return success since we have local backup
		return c.Status(201).JSON(fiber.Map{
			"message":  "Transaction saved to local backup (DB temporarily unavailable)",
			"trx_id":   transaction.TrxID,
			"db_saved": false,
		})
	}

	fmt.Printf("Transaction saved to AstraDB: %s\n", string(respBody))

	return c.Status(201).JSON(fiber.Map{
		"message":  "Transaction saved successfully",
		"trx_id":   transaction.TrxID,
		"db_saved": true,
	})
}

// saveTransactionToFile saves transaction to a local JSON Lines file
func saveTransactionToFile(transaction map[string]interface{}) error {
	file, err := os.OpenFile("transactions_fallback.jsonl", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	jsonData, err := json.Marshal(transaction)
	if err != nil {
		return err
	}

	_, err = file.WriteString(string(jsonData) + "\n")
	return err
}

// GetTransactionsByOutlet gets all transactions for a specific outlet
func (h *OrderHandler) GetTransactionsByOutlet(c *fiber.Ctx) error {
	outletID := c.Params("outlet_id")
	if outletID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "outlet_id is required"})
	}

	// Build filter for Data API
	filter := map[string]interface{}{
		"outlet_id": outletID,
	}

	// No pagination - get all data (AstraDB Data API max is 1000 per request)
	// For most outlets, this should be sufficient for daily operations
	options := map[string]interface{}{
		"sort":  map[string]interface{}{"created_at": -1},
		"limit": 1000, // Max allowed by AstraDB Data API
	}

	// Query from AstraDB Data API
	respBody, err := h.dbClient.FindDocuments("order", filter, options)
	if err != nil {
		fmt.Printf("Error fetching transactions from AstraDB: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch transactions from database"})
	}

	// Parse response
	var response struct {
		Data struct {
			Documents []map[string]interface{} `json:"documents"`
		} `json:"data"`
	}

	if err := json.Unmarshal(respBody, &response); err != nil {
		fmt.Printf("Error parsing response: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse database response"})
	}

	return c.JSON(fiber.Map{
		"transactions": response.Data.Documents,
		"count":        len(response.Data.Documents),
		"outlet_id":    outletID,
	})
}

// GetTransactionsByOutletAndDateRange gets transactions for outlet within date range
func (h *OrderHandler) GetTransactionsByOutletAndDateRange(c *fiber.Ctx) error {
	outletID := c.Params("outlet_id")
	startDate := c.Query("start_date") // format: YYYY-MM-DD
	endDate := c.Query("end_date")     // format: YYYY-MM-DD

	if outletID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "outlet_id is required"})
	}

	// Build filter
	filter := map[string]interface{}{
		"outlet_id": outletID,
	}

	// Add date filter if provided
	if startDate != "" && endDate != "" {
		filter["created_at"] = map[string]interface{}{
			"$gte": startDate + "T00:00:00Z",
			"$lte": endDate + "T23:59:59Z",
		}
	}

	// No pagination - get all data
	options := map[string]interface{}{
		"sort":  map[string]interface{}{"created_at": -1},
		"limit": 1000, // Max allowed by AstraDB Data API
	}

	respBody, err := h.dbClient.FindDocuments("order", filter, options)
	if err != nil {
		fmt.Printf("Error fetching transactions from AstraDB: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch transactions from database"})
	}

	var response struct {
		Data struct {
			Documents []map[string]interface{} `json:"documents"`
		} `json:"data"`
	}

	if err := json.Unmarshal(respBody, &response); err != nil {
		fmt.Printf("Error parsing response: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse database response"})
	}

	return c.JSON(fiber.Map{
		"transactions": response.Data.Documents,
		"count":        len(response.Data.Documents),
		"outlet_id":    outletID,
		"start_date":   startDate,
		"end_date":     endDate,
	})
}

// GetYearlyRecap gets yearly summary/statistics for an outlet (aggregated data)
func (h *OrderHandler) GetYearlyRecap(c *fiber.Ctx) error {
	outletID := c.Params("outlet_id")
	year := c.QueryInt("year", time.Now().Year())

	if outletID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "outlet_id is required"})
	}

	startDate := fmt.Sprintf("%d-01-01T00:00:00Z", year)
	endDate := fmt.Sprintf("%d-12-31T23:59:59Z", year)

	// Build filter for the entire year
	filter := map[string]interface{}{
		"outlet_id": outletID,
		"created_at": map[string]interface{}{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	// Fetch all transactions for the year (paginated internally)
	var allTransactions []map[string]interface{}
	page := 0
	batchSize := 1000

	for {
		options := map[string]interface{}{
			"sort":  map[string]interface{}{"created_at": -1},
			"limit": batchSize,
			"skip":  page * batchSize,
		}

		respBody, err := h.dbClient.FindDocuments("order", filter, options)
		if err != nil {
			fmt.Printf("Error fetching transactions: %v\n", err)
			break
		}

		var response struct {
			Data struct {
				Documents []map[string]interface{} `json:"documents"`
			} `json:"data"`
		}

		if err := json.Unmarshal(respBody, &response); err != nil {
			fmt.Printf("Error parsing response: %v\n", err)
			break
		}

		if len(response.Data.Documents) == 0 {
			break
		}

		allTransactions = append(allTransactions, response.Data.Documents...)
		
		// If we got less than batch size, no more data
		if len(response.Data.Documents) < batchSize {
			break
		}
		
		page++
		
		// Safety limit: max 50 pages (50,000 transactions per year per outlet)
		if page >= 50 {
			break
		}
	}

	// Calculate summary statistics
	var totalRevenue float64
	var totalTax float64
	var totalTransactions int
	monthlyRevenue := make(map[int]float64)    // month -> revenue
	monthlyCount := make(map[int]int)          // month -> transaction count
	paymentMethods := make(map[string]int)     // method -> count
	orderTypes := make(map[string]int)         // type -> count

	for _, trx := range allTransactions {
		totalTransactions++
		
		// Get total
		if total, ok := trx["total"].(float64); ok {
			totalRevenue += total
		}
		
		// Get tax
		if tax, ok := trx["tax"].(float64); ok {
			totalTax += tax
		}
		
		// Get month from created_at
		if createdAt, ok := trx["created_at"].(string); ok {
			if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
				month := int(t.Month())
				if total, ok := trx["total"].(float64); ok {
					monthlyRevenue[month] += total
				}
				monthlyCount[month]++
			}
		}
		
		// Count payment methods
		if method, ok := trx["method"].(string); ok {
			paymentMethods[method]++
		}
		
		// Count order types
		if orderType, ok := trx["type"].(string); ok {
			orderTypes[orderType]++
		}
	}

	// Build monthly breakdown
	monthlyBreakdown := make([]map[string]interface{}, 12)
	monthNames := []string{"Januari", "Februari", "Maret", "April", "Mei", "Juni", 
		"Juli", "Agustus", "September", "Oktober", "November", "Desember"}
	
	for i := 1; i <= 12; i++ {
		monthlyBreakdown[i-1] = map[string]interface{}{
			"month":        i,
			"month_name":   monthNames[i-1],
			"revenue":      monthlyRevenue[i],
			"transactions": monthlyCount[i],
		}
	}

	return c.JSON(fiber.Map{
		"outlet_id":          outletID,
		"year":               year,
		"total_transactions": totalTransactions,
		"total_revenue":      totalRevenue,
		"total_tax":          totalTax,
		"average_per_transaction": func() float64 {
			if totalTransactions > 0 {
				return totalRevenue / float64(totalTransactions)
			}
			return 0
		}(),
		"monthly_breakdown":  monthlyBreakdown,
		"payment_methods":    paymentMethods,
		"order_types":        orderTypes,
	})
}
