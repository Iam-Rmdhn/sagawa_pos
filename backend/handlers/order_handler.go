package handlers

import (
	"encoding/json"
	"fmt"
	"os"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/models"
	"strings"
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

	// Set created_at timestamp with WIB timezone (UTC+7)
	// Use fixed timezone to ensure consistency regardless of server location
	wib := time.FixedZone("WIB", 7*60*60) // UTC+7
	createdAt := time.Now().In(wib).Format(time.RFC3339)

	// Special handling for discount payments
	// Discount 100%: all payment values = 0 (completely free)
	// Discount < 100%: nominal/qris contains actual payment amount for revenue calculation
	nominal := transaction.Nominal
	qris := transaction.Qris
	changes := transaction.Changes
	total := transaction.Total

	// Debug logging for all transactions
	fmt.Printf("[SaveTransaction] TrxID=%s, Method=%s, Nominal=%f, Qris=%f, Total=%f\n",
		transaction.TrxID, transaction.Method, nominal, qris, total)

	if transaction.DiscountPercent != nil && *transaction.DiscountPercent == 100 {
		// For 100% discount: customer pays nothing
		nominal = 0
		qris = 0
		changes = 0
		total = 0
		fmt.Printf("[SaveTransaction] Discount 100%% detected - normalizing payment values to 0\n")
	} else if transaction.DiscountPercent != nil && *transaction.DiscountPercent > 0 {
		// For discount < 100%: nominal/qris already contains actual payment amount
		// This ensures revenue calculation uses actual money received
		fmt.Printf("[SaveTransaction] Discount %d%% detected - using nominal=%f, qris=%f for revenue\n",
			*transaction.DiscountPercent, nominal, qris)
	}

	// Debug logging for voucher payments
	if strings.Contains(strings.ToLower(transaction.Method), "voucher") {
		fmt.Printf("[SaveTransaction] Voucher payment detected - Method=%s, Nominal=%f, Qris=%f\n",
			transaction.Method, nominal, qris)
	}

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
		"nominal":     nominal,
		"subtotal":    transaction.Subtotal,
		"tax":         transaction.Tax,
		"total":       total,
		"qris":        qris,
		"changes":     changes,
		"created_at":  createdAt,
		"status":      "completed",
	}

	// Add discount fields if present
	if transaction.DiscountPercent != nil {
		document["discount_percent"] = *transaction.DiscountPercent
	}
	if transaction.DiscountAmount != nil {
		document["discount_amount"] = *transaction.DiscountAmount
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

// loadTransactionsFromFallback loads transactions from local fallback file
func (h *OrderHandler) loadTransactionsFromFallback(outletID string) ([]map[string]interface{}, error) {
	file, err := os.Open("transactions_fallback.jsonl")
	if err != nil {
		return nil, fmt.Errorf("failed to open fallback file: %v", err)
	}
	defer file.Close()

	var transactions []map[string]interface{}
	decoder := json.NewDecoder(file)

	for decoder.More() {
		var tx map[string]interface{}
		if err := decoder.Decode(&tx); err != nil {
			continue // Skip invalid lines
		}

		// Filter by outlet_id
		if txOutletID, ok := tx["outlet_id"].(string); ok && txOutletID == outletID {
			transactions = append(transactions, tx)
		}
	}

	return transactions, nil
}

// loadTransactionsFromFallbackWithDateRange loads transactions from local fallback file with date filtering
func (h *OrderHandler) loadTransactionsFromFallbackWithDateRange(outletID, startDate, endDate string) ([]map[string]interface{}, error) {
	file, err := os.Open("transactions_fallback.jsonl")
	if err != nil {
		return nil, fmt.Errorf("failed to open fallback file: %v", err)
	}
	defer file.Close()

	var transactions []map[string]interface{}
	decoder := json.NewDecoder(file)

	// Parse date range
	var startTime, endTime time.Time
	hasDateRange := startDate != "" && endDate != ""
	if hasDateRange {
		startTime, _ = time.Parse("2006-01-02", startDate)
		endTime, _ = time.Parse("2006-01-02", endDate)
		endTime = endTime.Add(24*time.Hour - time.Second) // End of day
	}

	for decoder.More() {
		var tx map[string]interface{}
		if err := decoder.Decode(&tx); err != nil {
			continue // Skip invalid lines
		}

		// Filter by outlet_id
		txOutletID, ok := tx["outlet_id"].(string)
		if !ok || txOutletID != outletID {
			continue
		}

		// Filter by date if range is provided
		if hasDateRange {
			createdAtStr, ok := tx["created_at"].(string)
			if !ok {
				continue
			}
			// Parse created_at (supports multiple formats)
			var txTime time.Time
			formats := []string{
				time.RFC3339,
				"2006-01-02T15:04:05Z07:00",
				"2006-01-02T15:04:05Z",
				"2006-01-02",
			}
			for _, format := range formats {
				if t, err := time.Parse(format, createdAtStr); err == nil {
					txTime = t
					break
				}
			}
			if txTime.IsZero() {
				continue
			}
			if txTime.Before(startTime) || txTime.After(endTime) {
				continue
			}
		}

		transactions = append(transactions, tx)
	}

	return transactions, nil
}

// GetTransactionsByOutlet gets all transactions for a specific outlet
func (h *OrderHandler) GetTransactionsByOutlet(c *fiber.Ctx) error {
	outletID := c.Params("outlet_id")
	fmt.Printf("[DEBUG] GetTransactionsByOutlet called with outlet_id: %s\n", outletID)

	if outletID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "outlet_id is required"})
	}

	// Build filter for Data API
	filter := map[string]interface{}{
		"outlet_id": outletID,
	}

	// Fetch all transactions with pagination using pageState
	// NOTE: AstraDB Data API does not support sort with pagination (pageState)
	// So we fetch all data without sort and sort in-memory at the end
	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	batchSize := 1000 // Increased for admin reporting - 1000 per page

	fmt.Printf("[GetTransactionsByOutlet] Starting fetch for outlet_id: %s\n", outletID)

	for {
		// NOTE: Removed "sort" because AstraDB Data API doesn't support sort with pageState pagination
		// We will sort in-memory after fetching all data
		options := map[string]interface{}{
			"limit": batchSize,
		}
		if pageState != "" {
			options["pageState"] = pageState
			fmt.Printf("[GetTransactionsByOutlet] Fetching page %d with pageState: %s...\n", pageCount+1, pageState[:min(20, len(pageState))])
		} else {
			fmt.Printf("[GetTransactionsByOutlet] Fetching first page (limit: %d)...\n", batchSize)
		}

		// Query from AstraDB Data API using config.DBClient
		respBody, err := config.DBClient.FindDocuments("order", filter, options)
		if err != nil {
			fmt.Printf("Error fetching transactions from AstraDB (page %d): %v\n", pageCount, err)

			// If first page fails, try fallback
			if pageCount == 0 {
				fmt.Println("Falling back to local file...")
				transactions, fallbackErr := h.loadTransactionsFromFallback(outletID)
				if fallbackErr != nil {
					fmt.Printf("Fallback also failed: %v\n", fallbackErr)
					return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch transactions from database and fallback"})
				}

				return c.JSON(fiber.Map{
					"transactions": transactions,
					"count":        len(transactions),
					"outlet_id":    outletID,
					"source":       "fallback",
				})
			}
			break
		}

		// Parse response with nextPageState from status object
		// AstraDB Data API may return pageState in different locations depending on version
		var response struct {
			Data struct {
				Documents     []map[string]interface{} `json:"documents"`
				NextPageState string                   `json:"nextPageState"` // v1 format
			} `json:"data"`
			Status struct {
				PageState     string `json:"pageState"`     // Some versions
				NextPageState string `json:"nextPageState"` // Some versions
			} `json:"status"`
		}

		if err := json.Unmarshal(respBody, &response); err != nil {
			fmt.Printf("Error parsing response (page %d): %v\n", pageCount, err)
			fmt.Printf("Response body: %s\n", string(respBody))
			break
		}

		// Determine the next page state from multiple possible locations
		nextPageState := response.Status.PageState
		if nextPageState == "" {
			nextPageState = response.Status.NextPageState
		}
		if nextPageState == "" {
			nextPageState = response.Data.NextPageState
		}

		fmt.Printf("[GetTransactionsByOutlet] Page %d: got %d documents, nextPageState: %s\n",
			pageCount, len(response.Data.Documents), nextPageState)

		// No more data
		if len(response.Data.Documents) == 0 {
			break
		}

		allTransactions = append(allTransactions, response.Data.Documents...)

		// Check for next page
		if nextPageState == "" {
			break
		}
		pageState = nextPageState
		pageCount++

		// Safety limit: max 500 pages (500,000 transactions) - increased for admin reporting
		if pageCount >= 500 {
			fmt.Printf("[WARNING] Reached max page limit of 500 pages. Total fetched: %d transactions\n", len(allTransactions))
			break
		}
	}

	fmt.Printf("[GetTransactionsByOutlet] Total transactions fetched: %d\n", len(allTransactions))

	// Sort transactions by created_at descending (newest first) in-memory
	sortTransactionsByDateDesc(allTransactions)

	return c.JSON(fiber.Map{
		"transactions": allTransactions,
		"count":        len(allTransactions),
		"outlet_id":    outletID,
		"source":       "database",
	})
}

// sortTransactionsByDateDesc sorts transactions by created_at field in descending order
func sortTransactionsByDateDesc(transactions []map[string]interface{}) {
	for i := 0; i < len(transactions)-1; i++ {
		for j := i + 1; j < len(transactions); j++ {
			dateI := getCreatedAtTime(transactions[i])
			dateJ := getCreatedAtTime(transactions[j])
			// Sort descending (newer first)
			if dateI.Before(dateJ) {
				transactions[i], transactions[j] = transactions[j], transactions[i]
			}
		}
	}
}

// getCreatedAtTime extracts created_at as time.Time from transaction
func getCreatedAtTime(tx map[string]interface{}) time.Time {
	if createdAt, ok := tx["created_at"].(string); ok {
		formats := []string{
			time.RFC3339,
			"2006-01-02T15:04:05Z07:00",
			"2006-01-02T15:04:05Z",
			"2006-01-02",
		}
		for _, format := range formats {
			if t, err := time.Parse(format, createdAt); err == nil {
				return t
			}
		}
	}
	return time.Time{} // Return zero time if parsing fails
}

// min returns the smaller of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
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

	// Fetch all transactions with pagination using pageState
	// NOTE: AstraDB Data API does not support sort with pagination (pageState)
	// So we fetch all data without sort and sort in-memory at the end
	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	batchSize := 1000 // Increased for admin reporting - 1000 per page

	for {
		// NOTE: Removed "sort" because AstraDB Data API doesn't support sort with pageState pagination
		options := map[string]interface{}{
			"limit": batchSize,
		}
		if pageState != "" {
			options["pageState"] = pageState
		}

		respBody, err := h.dbClient.FindDocuments("order", filter, options)
		if err != nil {
			fmt.Printf("Error fetching transactions from AstraDB (page %d): %v\n", pageCount, err)

			// If first page fails, try fallback
			if pageCount == 0 {
				fmt.Println("Falling back to local file...")
				transactions, fallbackErr := h.loadTransactionsFromFallbackWithDateRange(outletID, startDate, endDate)
				if fallbackErr != nil {
					fmt.Printf("Fallback also failed: %v\n", fallbackErr)
					return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch transactions from database and fallback"})
				}

				return c.JSON(fiber.Map{
					"transactions": transactions,
					"count":        len(transactions),
					"outlet_id":    outletID,
					"start_date":   startDate,
					"end_date":     endDate,
					"source":       "fallback",
				})
			}
			break
		}

		var response struct {
			Data struct {
				Documents []map[string]interface{} `json:"documents"`
			} `json:"data"`
			Status struct {
				PageState string `json:"pageState"`
			} `json:"status"`
		}

		if err := json.Unmarshal(respBody, &response); err != nil {
			fmt.Printf("Error parsing response (page %d): %v\n", pageCount, err)
			break
		}

		fmt.Printf("[GetTransactionsByOutletAndDateRange] Page %d: got %d documents, pageState: %s\n",
			pageCount, len(response.Data.Documents), response.Status.PageState)

		// No more data
		if len(response.Data.Documents) == 0 {
			break
		}

		allTransactions = append(allTransactions, response.Data.Documents...)

		// Check for next page
		if response.Status.PageState == "" {
			break
		}
		pageState = response.Status.PageState
		pageCount++

		// Safety limit: max 500 pages (500,000 transactions) - increased for admin reporting
		if pageCount >= 500 {
			fmt.Printf("[WARNING] Reached max page limit of 500 pages. Total fetched: %d transactions\n", len(allTransactions))
			break
		}
	}

	fmt.Printf("[GetTransactionsByOutletAndDateRange] Total transactions fetched: %d\n", len(allTransactions))

	// Sort transactions by created_at descending (newest first) in-memory
	sortTransactionsByDateDesc(allTransactions)

	return c.JSON(fiber.Map{
		"transactions": allTransactions,
		"count":        len(allTransactions),
		"outlet_id":    outletID,
		"start_date":   startDate,
		"end_date":     endDate,
		"source":       "database",
	})
}

// OutletInfo represents kasir/outlet information
type OutletInfo struct {
	ID        string `json:"id"`
	Username  string `json:"username"`
	Kemitraan string `json:"kemitraan"`
	Outlet    string `json:"outlet"`
	SubBrand  string `json:"sub_brand"`
}

// DailyOrder represents a single order in daily summary
type DailyOrder struct {
	ID            string                   `json:"id"`
	Total         float64                  `json:"total"`
	Items         []map[string]interface{} `json:"items"`
	PaymentMethod string                   `json:"paymentMethod"`
	Cashier       string                   `json:"cashier"`
	Customer      string                   `json:"customer"`
	Type          string                   `json:"type"`
	CreatedAt     string                   `json:"createdAt"`
}

// DailyIncome represents daily income summary
type DailyIncome struct {
	Date   string       `json:"date"`
	Total  float64      `json:"total"`
	Count  int          `json:"count"`
	Orders []DailyOrder `json:"orders"`
}

// OutletSummary represents outlet summary with daily income
type OutletSummary struct {
	OutletID        string        `json:"outletId"`
	Outlet          string        `json:"outlet"`
	Kemitraan       string        `json:"kemitraan"`
	OutletCabang    string        `json:"outletCabang"`
	SubBrand        string        `json:"subBrand"`
	TotalPendapatan float64       `json:"totalPendapatan"`
	JumlahTransaksi int           `json:"jumlahTransaksi"`
	DailyIncome     []DailyIncome `json:"dailyIncome"`
}

// parseOrderDate parses date from transaction
func parseOrderDate(createdAt interface{}) *time.Time {
	if createdAt == nil {
		return nil
	}

	var t time.Time
	var err error

	switch v := createdAt.(type) {
	case string:
		formats := []string{
			time.RFC3339,
			"2006-01-02T15:04:05Z07:00",
			"2006-01-02T15:04:05Z",
			"2006-01-02",
		}
		for _, format := range formats {
			t, err = time.Parse(format, v)
			if err == nil {
				return &t
			}
		}
	case time.Time:
		return &v
	}

	return nil
}

// getDateKey returns date key (YYYY-MM-DD) in Indonesia timezone (WIB)
func getDateKey(t time.Time) string {
	wib := time.FixedZone("WIB", 7*60*60) // UTC+7
	jakartaTime := t.In(wib)
	return fmt.Sprintf("%d-%02d-%02d", jakartaTime.Year(), jakartaTime.Month(), jakartaTime.Day())
}

// getMonthKey returns month key (YYYY-MM) in Indonesia timezone (WIB)
func getMonthKey(t time.Time) string {
	wib := time.FixedZone("WIB", 7*60*60) // UTC+7
	jakartaTime := t.In(wib)
	return fmt.Sprintf("%d-%02d", jakartaTime.Year(), jakartaTime.Month())
}

// normalizeOrderType normalizes order type to DI/TA/-
func normalizeOrderType(orderType interface{}) string {
	if orderType == nil {
		return "-"
	}

	rawType, ok := orderType.(string)
	if !ok {
		return "-"
	}

	upper := strings.ToUpper(rawType)
	if strings.Contains(upper, "TAKE") || upper == "TA" || strings.Contains(upper, "GRAB") || upper == "TAKE_AWAY" {
		return "TA"
	}
	if strings.Contains(upper, "DINE") || upper == "DI" || upper == "DINE_IN" {
		return "DI"
	}
	return upper
}

// GetAllTransactionsForAdmin gets all transactions without pagination for admin dashboard
// Similar to Next.js implementation - fetches all data and groups by outlet
func (h *OrderHandler) GetAllTransactionsForAdmin(c *fiber.Ctx) error {
	outletParam := c.Query("outlet") // Optional: filter by outlet_id
	month := c.Query("month")        // Optional: format YYYY-MM
	year := c.Query("year")          // Optional: format YYYY

	fmt.Printf("[GetAllTransactionsForAdmin] Params - outlet: %s, month: %s, year: %s\n", outletParam, month, year)

	// Step 1: Fetch all kasir/outlet data for mapping
	kasirResp, err := h.dbClient.FindDocuments("kasir_pos", map[string]interface{}{}, map[string]interface{}{
		"limit": 1000,
	})

	outletMap := make(map[string]OutletInfo)
	if err == nil {
		var kasirResponse struct {
			Data struct {
				Documents []map[string]interface{} `json:"documents"`
			} `json:"data"`
		}
		if json.Unmarshal(kasirResp, &kasirResponse) == nil {
			for _, kasir := range kasirResponse.Data.Documents {
				kasirID := ""
				if id, ok := kasir["id"].(string); ok {
					kasirID = id
				} else if id, ok := kasir["_id"].(string); ok {
					kasirID = id
				}
				if kasirID != "" {
					outletMap[kasirID] = OutletInfo{
						ID:        kasirID,
						Username:  toString(kasir["username"]),
						Kemitraan: toString(kasir["kemitraan"]),
						Outlet:    toString(kasir["outlet"]),
						SubBrand:  toString(kasir["subBrand"]),
					}
				}
			}
		}
	}
	fmt.Printf("[GetAllTransactionsForAdmin] Loaded %d kasir entries\n", len(outletMap))

	// Step 2: Build filter for orders
	filter := map[string]interface{}{}
	if outletParam != "" {
		filter["outlet_id"] = outletParam
	}

	// Step 3: Fetch ALL transactions with pagination (no limit)
	// NOTE: AstraDB Data API does not support sort with pagination (pageState)
	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	batchSize := 1000

	for {
		// NOTE: Removed "sort" because AstraDB Data API doesn't support sort with pageState pagination
		options := map[string]interface{}{
			"limit": batchSize,
		}
		if pageState != "" {
			options["pageState"] = pageState
		}

		respBody, err := h.dbClient.FindDocuments("order", filter, options)
		if err != nil {
			fmt.Printf("[GetAllTransactionsForAdmin] Error fetching page %d: %v\n", pageCount, err)
			break
		}

		var response struct {
			Data struct {
				Documents []map[string]interface{} `json:"documents"`
			} `json:"data"`
			Status struct {
				PageState string `json:"pageState"`
			} `json:"status"`
		}

		if err := json.Unmarshal(respBody, &response); err != nil {
			fmt.Printf("[GetAllTransactionsForAdmin] Error parsing page %d: %v\n", pageCount, err)
			break
		}

		if len(response.Data.Documents) == 0 {
			break
		}

		allTransactions = append(allTransactions, response.Data.Documents...)

		if response.Status.PageState == "" {
			break
		}
		pageState = response.Status.PageState
		pageCount++

		// Safety limit: max 1000 pages
		if pageCount >= 1000 {
			fmt.Printf("[WARNING] Reached max page limit. Total: %d transactions\n", len(allTransactions))
			break
		}
	}

	fmt.Printf("[GetAllTransactionsForAdmin] Total transactions fetched: %d\n", len(allTransactions))

	// Step 4: Filter by date and collect available months
	availableMonthsSet := make(map[string]bool)
	var filteredTransactions []map[string]interface{}

	for _, order := range allTransactions {
		orderDate := parseOrderDate(order["created_at"])
		if orderDate == nil {
			continue
		}

		// Collect available months
		monthKey := getMonthKey(*orderDate)
		availableMonthsSet[monthKey] = true

		// Filter by month or year if provided
		if month != "" {
			if monthKey != month {
				continue
			}
		} else if year != "" {
			if fmt.Sprintf("%d", orderDate.Year()) != year {
				continue
			}
		}

		filteredTransactions = append(filteredTransactions, order)
	}

	fmt.Printf("[GetAllTransactionsForAdmin] Filtered transactions: %d\n", len(filteredTransactions))

	// Step 5: Group by outlet and daily income
	outletSummaryMap := make(map[string]*OutletSummary)
	dailyIncomeMap := make(map[string]map[string]*DailyIncome) // outletID -> dateKey -> DailyIncome

	for _, order := range filteredTransactions {
		outletID := toString(order["outlet_id"])
		if outletID == "" {
			outletID = "unknown"
		}

		orderDate := parseOrderDate(order["created_at"])
		if orderDate == nil {
			continue
		}

		dateKey := getDateKey(*orderDate)
		total := toFloat64(order["total"])

		// Get or create outlet summary
		if _, exists := outletSummaryMap[outletID]; !exists {
			kasirInfo, hasKasir := outletMap[outletID]

			var outletDisplayName, displayBrand, outletCabang, subBrand string

			if hasKasir {
				kemitraan := kasirInfo.Kemitraan
				outletCabang = kasirInfo.Outlet
				subBrand = kasirInfo.SubBrand

				// For RM Nusantara, use subBrand as display brand
				if kemitraan == "RM Nusantara" && subBrand != "" {
					displayBrand = subBrand
				} else {
					displayBrand = kemitraan
				}

				if displayBrand != "" && outletCabang != "" {
					outletDisplayName = displayBrand + " - " + outletCabang
				} else if displayBrand != "" {
					outletDisplayName = displayBrand
				} else if outletCabang != "" {
					outletDisplayName = outletCabang
				} else {
					outletDisplayName = outletID
				}
			} else {
				// Fallback to order's outlet_name
				outletDisplayName = toString(order["outlet_name"])
				if outletDisplayName == "" {
					outletDisplayName = outletID
				}
				displayBrand = outletDisplayName
			}

			outletSummaryMap[outletID] = &OutletSummary{
				OutletID:        outletID,
				Outlet:          outletDisplayName,
				Kemitraan:       displayBrand,
				OutletCabang:    outletCabang,
				SubBrand:        subBrand,
				TotalPendapatan: 0,
				JumlahTransaksi: 0,
				DailyIncome:     []DailyIncome{},
			}
			dailyIncomeMap[outletID] = make(map[string]*DailyIncome)
		}

		// Update outlet summary
		outletSummaryMap[outletID].TotalPendapatan += total
		outletSummaryMap[outletID].JumlahTransaksi++

		// Get or create daily income
		if _, exists := dailyIncomeMap[outletID][dateKey]; !exists {
			dailyIncomeMap[outletID][dateKey] = &DailyIncome{
				Date:   dateKey,
				Total:  0,
				Count:  0,
				Orders: []DailyOrder{},
			}
		}

		dailyIncomeMap[outletID][dateKey].Total += total
		dailyIncomeMap[outletID][dateKey].Count++

		// Map items
		var items []map[string]interface{}
		if orderItems, ok := order["items"].([]interface{}); ok {
			for _, item := range orderItems {
				if itemMap, ok := item.(map[string]interface{}); ok {
					items = append(items, map[string]interface{}{
						"name":  toString(itemMap["menu_name"]),
						"qty":   toInt(itemMap["qty"]),
						"price": toFloat64(itemMap["price"]),
					})
				}
			}
		}

		// Add order to daily income
		orderID := toString(order["_id"])
		if orderID == "" {
			orderID = toString(order["trx_id"])
		}
		if orderID == "" {
			orderID = toString(order["id"])
		}

		dailyIncomeMap[outletID][dateKey].Orders = append(dailyIncomeMap[outletID][dateKey].Orders, DailyOrder{
			ID:            orderID,
			Total:         total,
			Items:         items,
			PaymentMethod: toString(order["method"]),
			Cashier:       toString(order["cashier"]),
			Customer:      toString(order["customer"]),
			Type:          normalizeOrderType(order["type"]),
			CreatedAt:     orderDate.Format(time.RFC3339),
		})
	}

	// Step 6: Convert to response format and sort daily income by date (descending)
	var outlets []OutletSummary
	for outletID, summary := range outletSummaryMap {
		// Convert daily income map to slice
		var dailyIncomes []DailyIncome
		for _, di := range dailyIncomeMap[outletID] {
			dailyIncomes = append(dailyIncomes, *di)
		}

		// Sort by date descending
		sortDailyIncomeDesc(dailyIncomes)

		summary.DailyIncome = dailyIncomes
		outlets = append(outlets, *summary)
	}

	// Convert available months to sorted slice (descending)
	var availableMonths []string
	for m := range availableMonthsSet {
		availableMonths = append(availableMonths, m)
	}
	sortStringsDesc(availableMonths)

	return c.JSON(fiber.Map{
		"outlets":         outlets,
		"availableMonths": availableMonths,
		"totalOrders":     len(filteredTransactions),
	})
}

// sortDailyIncomeDesc sorts daily income by date descending
func sortDailyIncomeDesc(dailyIncomes []DailyIncome) {
	for i := 0; i < len(dailyIncomes)-1; i++ {
		for j := i + 1; j < len(dailyIncomes); j++ {
			if dailyIncomes[i].Date < dailyIncomes[j].Date {
				dailyIncomes[i], dailyIncomes[j] = dailyIncomes[j], dailyIncomes[i]
			}
		}
	}
}

// sortStringsDesc sorts strings descending
func sortStringsDesc(strs []string) {
	for i := 0; i < len(strs)-1; i++ {
		for j := i + 1; j < len(strs); j++ {
			if strs[i] < strs[j] {
				strs[i], strs[j] = strs[j], strs[i]
			}
		}
	}
}

// toFloat64 converts interface to float64
func toFloat64(v interface{}) float64 {
	if v == nil {
		return 0
	}
	switch val := v.(type) {
	case float64:
		return val
	case float32:
		return float64(val)
	case int:
		return float64(val)
	case int64:
		return float64(val)
	case string:
		var f float64
		fmt.Sscanf(val, "%f", &f)
		return f
	}
	return 0
}

// toInt converts interface to int
func toInt(v interface{}) int {
	if v == nil {
		return 0
	}
	switch val := v.(type) {
	case int:
		return val
	case int64:
		return int(val)
	case float64:
		return int(val)
	case float32:
		return int(val)
	}
	return 0
}

// toString is already defined in helpers.go, but we add a local version for safety
func toStringVal(v interface{}) string {
	if v == nil {
		return ""
	}
	if s, ok := v.(string); ok {
		return s
	}
	return fmt.Sprintf("%v", v)
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
	// NOTE: AstraDB Data API does not support sort with pagination (pageState)
	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	batchSize := 1000 // Increased for yearly recap

	for {
		// NOTE: Removed "sort" because AstraDB Data API doesn't support sort with pageState pagination
		options := map[string]interface{}{
			"limit": batchSize,
		}
		if pageState != "" {
			options["pageState"] = pageState
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
			Status struct {
				PageState string `json:"pageState"`
			} `json:"status"`
		}

		if err := json.Unmarshal(respBody, &response); err != nil {
			fmt.Printf("Error parsing response: %v\n", err)
			break
		}

		if len(response.Data.Documents) == 0 {
			break
		}

		allTransactions = append(allTransactions, response.Data.Documents...)

		// Check for next page
		if response.Status.PageState == "" {
			break
		}
		pageState = response.Status.PageState
		pageCount++

		// Safety limit: max 200 pages (200,000 transactions per year) - increased for yearly reporting
		if pageCount >= 200 {
			fmt.Printf("[WARNING] Reached max page limit of 200 pages for yearly recap. Total fetched: %d transactions\n", len(allTransactions))
			break
		}
	}

	// Calculate summary statistics
	var totalRevenue float64
	var totalTax float64
	var totalTransactions int
	monthlyRevenue := make(map[int]float64) // month -> revenue
	monthlyCount := make(map[int]int)       // month -> transaction count
	paymentMethods := make(map[string]int)  // method -> count
	orderTypes := make(map[string]int)      // type -> count

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
		"monthly_breakdown": monthlyBreakdown,
		"payment_methods":   paymentMethods,
		"order_types":       orderTypes,
	})
}
