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

func (h *OrderHandler) SaveTransaction(c *fiber.Ctx) error {
	var transaction models.Transaction
	if err := c.BodyParser(&transaction); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

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

	wib := time.FixedZone("WIB", 7*60*60)
	createdAt := time.Now().In(wib).Format(time.RFC3339)

	subtotal := transaction.Subtotal
	var potongan float64 = 0
	isVoucher := strings.Contains(strings.ToLower(transaction.Method), "voucher")
	isDiscount := strings.Contains(strings.ToLower(transaction.Method), "discount")
	isTaxEnabled := transaction.Tax > 0

	if isVoucher && transaction.VoucherAmount != nil {
		potongan = *transaction.VoucherAmount
	} else if isDiscount && transaction.DiscountAmount != nil {
		potongan = *transaction.DiscountAmount
	}

	subtotalAfterPotongan := CalculateSubtotalAfterPotongan(subtotal, potongan)

	var tax float64 = 0
	var total float64 = 0

	if isVoucher || isDiscount {

		if isTaxEnabled {
			tax = CalculateTax(subtotalAfterPotongan)
		}
		total = subtotalAfterPotongan + tax
	} else {

		if isTaxEnabled {
			tax = CalculateTax(subtotal)
		}
		total = subtotal + tax
	}

	nominal := transaction.Nominal
	qris := transaction.Qris
	changes := transaction.Changes

	fmt.Printf("[SaveTransaction] TrxID=%s, Method=%s\n", transaction.TrxID, transaction.Method)
	fmt.Printf("[SaveTransaction] Subtotal=%f, Potongan=%f, SubtotalAfterPotongan=%f\n",
		subtotal, potongan, subtotalAfterPotongan)
	fmt.Printf("[SaveTransaction] Frontend: Tax=%f, Total=%f\n", transaction.Tax, transaction.Total)
	fmt.Printf("[SaveTransaction] Calculated: Tax=%f, Total=%f\n", tax, total)

	if transaction.DiscountPercent != nil && *transaction.DiscountPercent == 100 {
		nominal = 0
		qris = 0
		changes = 0
		total = 0
		tax = 0
		fmt.Printf("[SaveTransaction] Discount 100%% detected - normalizing all values to 0\n")
	}

	if isVoucher && transaction.VoucherAmount != nil && *transaction.VoucherAmount >= subtotal {

		total = 0
		tax = 0
		nominal = 0
		qris = 0
		changes = 0
		fmt.Printf("[SaveTransaction] Voucher covers entire order - normalizing to 0\n")
	}

	document := map[string]interface{}{
		"_id":         transaction.TrxID,
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
		"subtotal":    subtotal,
		"tax":         tax,
		"total":       total,
		"qris":        qris,
		"changes":     changes,
		"created_at":  createdAt,
		"status":      "completed",
	}

	if potongan > 0 {
		document["subtotal_after_potongan"] = subtotalAfterPotongan
	}

	if transaction.DiscountPercent != nil {
		document["discount_percent"] = *transaction.DiscountPercent
	}
	if transaction.DiscountAmount != nil {
		document["discount_amount"] = *transaction.DiscountAmount
	}

	if transaction.VoucherCode != nil {
		document["voucher_code"] = *transaction.VoucherCode
	}
	if transaction.VoucherAmount != nil {
		document["voucher_amount"] = *transaction.VoucherAmount
	}
	if transaction.AdditionalPayment != nil {
		document["additional_payment"] = *transaction.AdditionalPayment
	}
	if transaction.AdditionalPaymentMethod != nil {
		document["additional_payment_method"] = *transaction.AdditionalPaymentMethod
	}

	if err := saveTransactionToFile(document); err != nil {
		fmt.Printf("Warning: Failed to save transaction to local file: %v\n", err)
	}

	respBody, dbErr := h.dbClient.InsertDocument("order", document)
	if dbErr != nil {
		fmt.Printf("Warning: Failed to save to AstraDB: %v\n", dbErr)

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
			continue
		}

		if txOutletID, ok := tx["outlet_id"].(string); ok && txOutletID == outletID {
			transactions = append(transactions, tx)
		}
	}

	return transactions, nil
}

func (h *OrderHandler) loadTransactionsFromFallbackWithDateRange(outletID, startDate, endDate string) ([]map[string]interface{}, error) {
	file, err := os.Open("transactions_fallback.jsonl")
	if err != nil {
		return nil, fmt.Errorf("failed to open fallback file: %v", err)
	}
	defer file.Close()

	var transactions []map[string]interface{}
	decoder := json.NewDecoder(file)

	var startTime, endTime time.Time
	hasDateRange := startDate != "" && endDate != ""
	if hasDateRange {
		startTime, _ = time.Parse("2006-01-02", startDate)
		endTime, _ = time.Parse("2006-01-02", endDate)
		endTime = endTime.Add(24*time.Hour - time.Second)
	}

	for decoder.More() {
		var tx map[string]interface{}
		if err := decoder.Decode(&tx); err != nil {
			continue
		}

		txOutletID, ok := tx["outlet_id"].(string)
		if !ok || txOutletID != outletID {
			continue
		}

		if hasDateRange {
			createdAtStr, ok := tx["created_at"].(string)
			if !ok {
				continue
			}

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

func (h *OrderHandler) GetTransactionsByOutlet(c *fiber.Ctx) error {
	outletID := c.Params("outlet_id")
	fmt.Printf("[DEBUG] GetTransactionsByOutlet called with outlet_id: %s\n", outletID)

	if outletID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "outlet_id is required"})
	}

	filter := map[string]interface{}{
		"outlet_id": outletID,
	}

	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	// Use high limit to fetch all transactions for the outlet
	// Sort will be done in Go after fetching
	batchSize := 10000

	fmt.Printf("[GetTransactionsByOutlet] Starting fetch for outlet_id: %s\n", outletID)

	for {

		options := map[string]interface{}{
			"limit": batchSize,
		}
		if pageState != "" {
			options["pageState"] = pageState
			fmt.Printf("[GetTransactionsByOutlet] Fetching page %d with pageState: %s...\n", pageCount+1, pageState[:min(20, len(pageState))])
		} else {
			fmt.Printf("[GetTransactionsByOutlet] Fetching first page (limit: %d)...\n", batchSize)
		}

		respBody, err := config.DBClient.FindDocuments("order", filter, options)
		if err != nil {
			fmt.Printf("Error fetching transactions from AstraDB (page %d): %v\n", pageCount, err)

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

		// AstraDB Data API response structure can vary
		// Try parsing with different structures
		var response struct {
			Data struct {
				Documents     []map[string]interface{} `json:"documents"`
				NextPageState string                   `json:"nextPageState"`
			} `json:"data"`
			Status struct {
				PageState     string `json:"pageState"`
				NextPageState string `json:"nextPageState"`
			} `json:"status"`
			// AstraDB JSON API v1 format - documents at root
			Documents     []map[string]interface{} `json:"documents"`
			NextPageState string                   `json:"nextPageState"`
		}

		if err := json.Unmarshal(respBody, &response); err != nil {
			fmt.Printf("Error parsing response (page %d): %v\n", pageCount, err)
			fmt.Printf("Response body: %s\n", string(respBody))
			break
		}

		// Log raw response for debugging (first 500 chars)
		respStr := string(respBody)
		if len(respStr) > 500 {
			fmt.Printf("[GetTransactionsByOutlet] Raw response (first 500 chars): %s...\n", respStr[:500])
		} else {
			fmt.Printf("[GetTransactionsByOutlet] Raw response: %s\n", respStr)
		}

		// Get documents from whichever location has them
		documents := response.Documents
		if len(documents) == 0 {
			documents = response.Data.Documents
		}

		// Try to get nextPageState from different locations (AstraDB response varies)
		nextPageState := response.NextPageState
		if nextPageState == "" {
			nextPageState = response.Status.PageState
		}
		if nextPageState == "" {
			nextPageState = response.Status.NextPageState
		}
		if nextPageState == "" {
			nextPageState = response.Data.NextPageState
		}

		// Also try to extract from raw JSON if still empty
		if nextPageState == "" {
			var rawMap map[string]interface{}
			if err := json.Unmarshal(respBody, &rawMap); err == nil {
				// Check various possible locations
				if ps, ok := rawMap["nextPageState"].(string); ok && ps != "" {
					nextPageState = ps
				} else if data, ok := rawMap["data"].(map[string]interface{}); ok {
					if ps, ok := data["nextPageState"].(string); ok && ps != "" {
						nextPageState = ps
					}
				} else if status, ok := rawMap["status"].(map[string]interface{}); ok {
					if ps, ok := status["nextPageState"].(string); ok && ps != "" {
						nextPageState = ps
					}
				}
			}
		}

		fmt.Printf("[GetTransactionsByOutlet] Page %d: got %d documents, nextPageState present: %v\n",
			pageCount, len(documents), nextPageState != "")

		if len(documents) == 0 {
			break
		}

		allTransactions = append(allTransactions, documents...)

		if nextPageState == "" {
			fmt.Printf("[GetTransactionsByOutlet] No more pages (nextPageState is empty)\n")
			break
		}
		pageState = nextPageState
		pageCount++

		if pageCount >= 500 {
			fmt.Printf("[WARNING] Reached max page limit of 500 pages. Total fetched: %d transactions\n", len(allTransactions))
			break
		}
	}

	fmt.Printf("[GetTransactionsByOutlet] Total transactions fetched: %d\n", len(allTransactions))

	sortTransactionsByDateDesc(allTransactions)

	return c.JSON(fiber.Map{
		"transactions": allTransactions,
		"count":        len(allTransactions),
		"outlet_id":    outletID,
		"source":       "database",
	})
}

func sortTransactionsByDateDesc(transactions []map[string]interface{}) {
	for i := 0; i < len(transactions)-1; i++ {
		for j := i + 1; j < len(transactions); j++ {
			dateI := getCreatedAtTime(transactions[i])
			dateJ := getCreatedAtTime(transactions[j])

			if dateI.Before(dateJ) {
				transactions[i], transactions[j] = transactions[j], transactions[i]
			}
		}
	}
}

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
	return time.Time{}
}

func getCreatedAtTimeWIB(tx map[string]interface{}, wib *time.Location) time.Time {
	if createdAt, ok := tx["created_at"].(string); ok {
		formats := []string{
			time.RFC3339,
			"2006-01-02T15:04:05Z07:00",
			"2006-01-02T15:04:05+07:00",
			"2006-01-02T15:04:05Z",
			"2006-01-02T15:04:05",
			"2006-01-02",
		}
		for _, format := range formats {
			if t, err := time.Parse(format, createdAt); err == nil {
				// If parsed as UTC (ends with Z), convert to WIB
				if t.Location() == time.UTC {
					return t.In(wib)
				}
				// If it has timezone info, keep it but represent in WIB
				return t.In(wib)
			}
		}

		// Try parsing with location for dates without timezone
		for _, format := range []string{"2006-01-02T15:04:05", "2006-01-02"} {
			if t, err := time.ParseInLocation(format, createdAt, wib); err == nil {
				return t
			}
		}
	}
	return time.Time{}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func (h *OrderHandler) GetTransactionsByOutletAndDateRange(c *fiber.Ctx) error {
	outletID := c.Params("outlet_id")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	if outletID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "outlet_id is required"})
	}

	fmt.Printf("[GetTransactionsByOutletAndDateRange] outletID=%s, startDate=%s, endDate=%s\n", outletID, startDate, endDate)
	fmt.Println("[GetTransactionsByOutletAndDateRange] CODE VERSION: 2026-02-06_FIX_LIMIT_10000_NO_SORT")

	// Only filter by outlet_id, date filtering will be done in Go
	// because AstraDB Data API may not support $gte/$lte on string dates properly
	filter := map[string]interface{}{
		"outlet_id": outletID,
	}

	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	// Use high limit to fetch all transactions for the outlet
	// Sort will be done in Go after date filtering
	// Note: AstraDB sort with filter limits results to 20, so we sort in Go instead
	batchSize := 10000

	for {

		options := map[string]interface{}{
			"limit": batchSize,
		}
		if pageState != "" {
			options["pageState"] = pageState
		}

		respBody, err := h.dbClient.FindDocuments("order", filter, options)
		if err != nil {
			fmt.Printf("Error fetching transactions from AstraDB (page %d): %v\n", pageCount, err)

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

		// AstraDB Data API response structure can vary
		// Try parsing with different structures
		var response struct {
			Data struct {
				Documents     []map[string]interface{} `json:"documents"`
				NextPageState string                   `json:"nextPageState"`
			} `json:"data"`
			Status struct {
				PageState     string `json:"pageState"`
				NextPageState string `json:"nextPageState"`
			} `json:"status"`
			// AstraDB JSON API v1 format - documents at root
			Documents     []map[string]interface{} `json:"documents"`
			NextPageState string                   `json:"nextPageState"`
		}

		if err := json.Unmarshal(respBody, &response); err != nil {
			fmt.Printf("Error parsing response (page %d): %v\n", pageCount, err)
			break
		}

		// Log raw response for debugging (first 500 chars)
		respStr := string(respBody)
		if len(respStr) > 500 {
			fmt.Printf("[GetTransactionsByOutletAndDateRange] Raw response (first 500 chars): %s...\n", respStr[:500])
		} else {
			fmt.Printf("[GetTransactionsByOutletAndDateRange] Raw response: %s\n", respStr)
		}

		// Get documents from whichever location has them
		documents := response.Documents
		if len(documents) == 0 {
			documents = response.Data.Documents
		}

		// Try to get nextPageState from different locations (AstraDB response varies)
		nextPageState := response.NextPageState
		if nextPageState == "" {
			nextPageState = response.Status.PageState
		}
		if nextPageState == "" {
			nextPageState = response.Status.NextPageState
		}
		if nextPageState == "" {
			nextPageState = response.Data.NextPageState
		}

		// Also try to extract from raw JSON if still empty
		if nextPageState == "" {
			var rawMap map[string]interface{}
			if err := json.Unmarshal(respBody, &rawMap); err == nil {
				// Check various possible locations
				if ps, ok := rawMap["nextPageState"].(string); ok && ps != "" {
					nextPageState = ps
				} else if data, ok := rawMap["data"].(map[string]interface{}); ok {
					if ps, ok := data["nextPageState"].(string); ok && ps != "" {
						nextPageState = ps
					}
				} else if status, ok := rawMap["status"].(map[string]interface{}); ok {
					if ps, ok := status["nextPageState"].(string); ok && ps != "" {
						nextPageState = ps
					}
				}
			}
		}

		fmt.Printf("[GetTransactionsByOutletAndDateRange] Page %d: got %d documents, nextPageState present: %v\n",
			pageCount, len(documents), nextPageState != "")

		if len(documents) == 0 {
			break
		}

		allTransactions = append(allTransactions, documents...)

		if nextPageState == "" {
			fmt.Printf("[GetTransactionsByOutletAndDateRange] No more pages (nextPageState is empty)\n")
			break
		}
		pageState = nextPageState
		pageCount++

		if pageCount >= 500 {
			fmt.Printf("[WARNING] Reached max page limit of 500 pages. Total fetched: %d transactions\n", len(allTransactions))
			break
		}
	}

	fmt.Printf("[GetTransactionsByOutletAndDateRange] Total transactions fetched before filtering: %d\n", len(allTransactions))

	// Filter by date range in Go
	// Use WIB timezone (UTC+7) for Indonesia
	wib := time.FixedZone("WIB", 7*60*60)

	var filteredTransactions []map[string]interface{}
	if startDate != "" && endDate != "" {
		// Parse dates as WIB timezone start/end of day
		startTime, _ := time.ParseInLocation("2006-01-02", startDate, wib)
		endTime, _ := time.ParseInLocation("2006-01-02", endDate, wib)
		// Set end time to end of day in WIB
		endTime = endTime.Add(23*time.Hour + 59*time.Minute + 59*time.Second)

		fmt.Printf("[GetTransactionsByOutletAndDateRange] Filter range (WIB): %v to %v\n", startTime, endTime)
		fmt.Printf("[GetTransactionsByOutletAndDateRange] Filter range (UTC): %v to %v\n", startTime.UTC(), endTime.UTC())

		skippedCount := 0
		skippedDates := []string{}
		for _, tx := range allTransactions {
			txTime := getCreatedAtTimeWIB(tx, wib)
			if txTime.IsZero() {
				skippedCount++
				if createdAt, ok := tx["created_at"].(string); ok {
					if len(skippedDates) < 5 { // Log first 5 unparseable dates
						skippedDates = append(skippedDates, createdAt)
					}
				}
				continue
			}
			if !txTime.Before(startTime) && !txTime.After(endTime) {
				filteredTransactions = append(filteredTransactions, tx)
			}
		}

		if skippedCount > 0 {
			fmt.Printf("[GetTransactionsByOutletAndDateRange] WARNING: %d transactions skipped (unparseable dates)\n", skippedCount)
			fmt.Printf("[GetTransactionsByOutletAndDateRange] Sample unparseable dates: %v\n", skippedDates)
		}

		fmt.Printf("[GetTransactionsByOutletAndDateRange] After date filtering: %d transactions\n", len(filteredTransactions))

		// Log transaction counts per date for debugging
		dateCounts := make(map[string]int)
		for _, tx := range filteredTransactions {
			txTime := getCreatedAtTimeWIB(tx, wib)
			if !txTime.IsZero() {
				dateKey := txTime.Format("2006-01-02")
				dateCounts[dateKey]++
			}
		}
		fmt.Printf("[GetTransactionsByOutletAndDateRange] Transactions per date (WIB):\n")
		for date, count := range dateCounts {
			fmt.Printf("  %s: %d transactions\n", date, count)
		}
	} else {
		filteredTransactions = allTransactions
	}

	sortTransactionsByDateDesc(filteredTransactions)

	return c.JSON(fiber.Map{
		"transactions": filteredTransactions,
		"count":        len(filteredTransactions),
		"outlet_id":    outletID,
		"start_date":   startDate,
		"end_date":     endDate,
		"source":       "database",
		"_version":     "FIX_LIMIT_10000_NO_SORT", // Debug field to verify deployment
	})
}

type OutletInfo struct {
	ID        string `json:"id"`
	Username  string `json:"username"`
	Kemitraan string `json:"kemitraan"`
	Outlet    string `json:"outlet"`
	SubBrand  string `json:"sub_brand"`
}

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

type DailyIncome struct {
	Date   string       `json:"date"`
	Total  float64      `json:"total"`
	Count  int          `json:"count"`
	Orders []DailyOrder `json:"orders"`
}

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

func getDateKey(t time.Time) string {
	wib := time.FixedZone("WIB", 7*60*60)
	jakartaTime := t.In(wib)
	return fmt.Sprintf("%d-%02d-%02d", jakartaTime.Year(), jakartaTime.Month(), jakartaTime.Day())
}

func getMonthKey(t time.Time) string {
	wib := time.FixedZone("WIB", 7*60*60)
	jakartaTime := t.In(wib)
	return fmt.Sprintf("%d-%02d", jakartaTime.Year(), jakartaTime.Month())
}

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

func (h *OrderHandler) GetAllTransactionsForAdmin(c *fiber.Ctx) error {
	outletParam := c.Query("outlet")
	month := c.Query("month")
	year := c.Query("year")

	fmt.Printf("[GetAllTransactionsForAdmin] Params - outlet: %s, month: %s, year: %s\n", outletParam, month, year)

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

	filter := map[string]interface{}{}
	if outletParam != "" {
		filter["outlet_id"] = outletParam
	}

	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	batchSize := 1000

	for {

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

		if pageCount >= 1000 {
			fmt.Printf("[WARNING] Reached max page limit. Total: %d transactions\n", len(allTransactions))
			break
		}
	}

	fmt.Printf("[GetAllTransactionsForAdmin] Total transactions fetched: %d\n", len(allTransactions))

	availableMonthsSet := make(map[string]bool)
	var filteredTransactions []map[string]interface{}

	for _, order := range allTransactions {
		orderDate := parseOrderDate(order["created_at"])
		if orderDate == nil {
			continue
		}

		monthKey := getMonthKey(*orderDate)
		availableMonthsSet[monthKey] = true

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

	outletSummaryMap := make(map[string]*OutletSummary)
	dailyIncomeMap := make(map[string]map[string]*DailyIncome)

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

		if _, exists := outletSummaryMap[outletID]; !exists {
			kasirInfo, hasKasir := outletMap[outletID]

			var outletDisplayName, displayBrand, outletCabang, subBrand string

			if hasKasir {
				kemitraan := kasirInfo.Kemitraan
				outletCabang = kasirInfo.Outlet
				subBrand = kasirInfo.SubBrand

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

		outletSummaryMap[outletID].TotalPendapatan += total
		outletSummaryMap[outletID].JumlahTransaksi++

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

	var outlets []OutletSummary
	for outletID, summary := range outletSummaryMap {

		var dailyIncomes []DailyIncome
		for _, di := range dailyIncomeMap[outletID] {
			dailyIncomes = append(dailyIncomes, *di)
		}

		sortDailyIncomeDesc(dailyIncomes)

		summary.DailyIncome = dailyIncomes
		outlets = append(outlets, *summary)
	}

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

func sortDailyIncomeDesc(dailyIncomes []DailyIncome) {
	for i := 0; i < len(dailyIncomes)-1; i++ {
		for j := i + 1; j < len(dailyIncomes); j++ {
			if dailyIncomes[i].Date < dailyIncomes[j].Date {
				dailyIncomes[i], dailyIncomes[j] = dailyIncomes[j], dailyIncomes[i]
			}
		}
	}
}

func sortStringsDesc(strs []string) {
	for i := 0; i < len(strs)-1; i++ {
		for j := i + 1; j < len(strs); j++ {
			if strs[i] < strs[j] {
				strs[i], strs[j] = strs[j], strs[i]
			}
		}
	}
}

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

func toStringVal(v interface{}) string {
	if v == nil {
		return ""
	}
	if s, ok := v.(string); ok {
		return s
	}
	return fmt.Sprintf("%v", v)
}

func (h *OrderHandler) GetYearlyRecap(c *fiber.Ctx) error {
	outletID := c.Params("outlet_id")
	year := c.QueryInt("year", time.Now().Year())

	if outletID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "outlet_id is required"})
	}

	startDate := fmt.Sprintf("%d-01-01T00:00:00Z", year)
	endDate := fmt.Sprintf("%d-12-31T23:59:59Z", year)

	filter := map[string]interface{}{
		"outlet_id": outletID,
		"created_at": map[string]interface{}{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	var allTransactions []map[string]interface{}
	pageState := ""
	pageCount := 0
	batchSize := 1000

	for {

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

		if response.Status.PageState == "" {
			break
		}
		pageState = response.Status.PageState
		pageCount++

		if pageCount >= 200 {
			fmt.Printf("[WARNING] Reached max page limit of 200 pages for yearly recap. Total fetched: %d transactions\n", len(allTransactions))
			break
		}
	}

	var totalRevenue float64
	var totalTax float64
	var totalTransactions int
	monthlyRevenue := make(map[int]float64)
	monthlyCount := make(map[int]int)
	paymentMethods := make(map[string]int)
	orderTypes := make(map[string]int)

	for _, trx := range allTransactions {
		totalTransactions++

		if total, ok := trx["total"].(float64); ok {
			totalRevenue += total
		}

		if tax, ok := trx["tax"].(float64); ok {
			totalTax += tax
		}

		if createdAt, ok := trx["created_at"].(string); ok {
			if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
				month := int(t.Month())
				if total, ok := trx["total"].(float64); ok {
					monthlyRevenue[month] += total
				}
				monthlyCount[month]++
			}
		}

		if method, ok := trx["method"].(string); ok {
			paymentMethods[method]++
		}

		if orderType, ok := trx["type"].(string); ok {
			orderTypes[orderType]++
		}
	}

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
