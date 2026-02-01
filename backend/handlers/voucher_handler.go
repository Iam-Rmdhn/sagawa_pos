package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/models"
	"time"

	"github.com/gofiber/fiber/v2"
)

type VoucherHandler struct {
	dbClient *config.AstraDBClient
}

func NewVoucherHandler(dbClient *config.AstraDBClient) *VoucherHandler {
	return &VoucherHandler{dbClient: dbClient}
}

func (h *VoucherHandler) VerifyVoucher(c *fiber.Ctx) error {
	var req models.VerifyVoucherRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.VerifyVoucherResponse{
			Success: false,
			Message: "Format request tidak valid",
		})
	}

	if req.CodeVoucher == "" {
		return c.Status(fiber.StatusBadRequest).JSON(models.VerifyVoucherResponse{
			Success: false,
			Message: "Kode voucher tidak boleh kosong",
		})
	}

	fmt.Printf("DEBUG: Verifying voucher code: %s\n", req.CodeVoucher)
	fmt.Printf("DEBUG: DataAPIURL: %s\n", h.dbClient.DataAPIURL)

	queryBody := map[string]interface{}{
		"find": map[string]interface{}{
			"filter": map[string]interface{}{
				"code_voucher": req.CodeVoucher,
			},
		},
	}

	url := fmt.Sprintf("%s/voucher", h.dbClient.DataAPIURL)
	bodyBytes, _ := json.Marshal(queryBody)

	fmt.Printf("DEBUG: Request URL: %s\n", url)
	fmt.Printf("DEBUG: Request Body: %s\n", string(bodyBytes))

	httpReq, err := http.NewRequest("POST", url, bytes.NewBuffer(bodyBytes))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.VerifyVoucherResponse{
			Success: false,
			Message: "Gagal membuat request ke database",
		})
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-Cassandra-Token", h.dbClient.Token)

	resp, err := h.dbClient.Client.Do(httpReq)
	if err != nil {
		fmt.Printf("DEBUG: Error executing request: %v\n", err)
		return c.Status(fiber.StatusInternalServerError).JSON(models.VerifyVoucherResponse{
			Success: false,
			Message: "Gagal mengakses database",
		})
	}
	defer resp.Body.Close()

	bodyData, _ := io.ReadAll(resp.Body)
	fmt.Printf("DEBUG: Response Status: %d\n", resp.StatusCode)
	fmt.Printf("DEBUG: Response Body: %s\n", string(bodyData))

	resp.Body = io.NopCloser(bytes.NewBuffer(bodyData))

	var queryResponse struct {
		Data struct {
			Documents []map[string]interface{} `json:"documents"`
		} `json:"data"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&queryResponse); err != nil {
		fmt.Printf("DEBUG: Error decoding response: %v\n", err)
		return c.Status(fiber.StatusInternalServerError).JSON(models.VerifyVoucherResponse{
			Success: false,
			Message: "Gagal membaca response database",
		})
	}

	fmt.Printf("DEBUG: Found %d voucher(s)\n", len(queryResponse.Data.Documents))

	if len(queryResponse.Data.Documents) == 0 {
		return c.Status(fiber.StatusNotFound).JSON(models.VerifyVoucherResponse{
			Success: false,
			Message: "Kode voucher tidak ditemukan",
		})
	}

	voucherData := queryResponse.Data.Documents[0]

	isUsed, ok := voucherData["used"].(bool)
	if ok && isUsed {
		return c.Status(fiber.StatusBadRequest).JSON(models.VerifyVoucherResponse{
			Success: false,
			Message: "Voucher sudah pernah digunakan",
		})
	}

	nominal := 0
	if nominalVal, ok := voucherData["nominal"].(float64); ok {
		nominal = int(nominalVal)
	} else if nominalVal, ok := voucherData["nominal"].(int); ok {
		nominal = nominalVal
	}

	return c.Status(fiber.StatusOK).JSON(models.VerifyVoucherResponse{
		Success:     true,
		Message:     "Voucher berhasil diverifikasi",
		CodeVoucher: req.CodeVoucher,
		Nominal:     nominal,
	})
}

func (h *VoucherHandler) UseVoucher(c *fiber.Ctx) error {
	var req models.UseVoucherRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Format request tidak valid",
		})
	}

	if req.CodeVoucher == "" {
		return c.Status(fiber.StatusBadRequest).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Kode voucher tidak boleh kosong",
		})
	}

	queryBody := map[string]interface{}{
		"find": map[string]interface{}{
			"filter": map[string]interface{}{
				"code_voucher": req.CodeVoucher,
			},
		},
	}

	url := fmt.Sprintf("%s/voucher", h.dbClient.DataAPIURL)
	bodyBytes, _ := json.Marshal(queryBody)

	httpReq, err := http.NewRequest("POST", url, bytes.NewBuffer(bodyBytes))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Gagal membuat request ke database",
		})
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-Cassandra-Token", h.dbClient.Token)

	resp, err := h.dbClient.Client.Do(httpReq)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Gagal mengakses database",
		})
	}
	defer resp.Body.Close()

	var queryResponse struct {
		Data struct {
			Documents []map[string]interface{} `json:"documents"`
		} `json:"data"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&queryResponse); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Gagal membaca response database",
		})
	}

	if len(queryResponse.Data.Documents) == 0 {
		return c.Status(fiber.StatusNotFound).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Kode voucher tidak ditemukan",
		})
	}

	voucherData := queryResponse.Data.Documents[0]

	isUsed, ok := voucherData["used"].(bool)
	if ok && isUsed {
		return c.Status(fiber.StatusBadRequest).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Voucher sudah pernah digunakan",
		})
	}

	nominal := 0
	if nominalVal, ok := voucherData["nominal"].(float64); ok {
		nominal = int(nominalVal)
	} else if nominalVal, ok := voucherData["nominal"].(int); ok {
		nominal = nominalVal
	}

	voucherID, ok := voucherData["_id"].(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Data voucher tidak valid",
		})
	}

	updateFields := map[string]interface{}{
		"$set": map[string]interface{}{
			"used":   true,
			"usedAt": time.Now().Format(time.RFC3339),
		},
	}

	if req.RedeemedBy != "" {
		updateFields["$set"].(map[string]interface{})["redeemedBy"] = req.RedeemedBy
		fmt.Printf("DEBUG: Adding redeemedBy to update: %s\n", req.RedeemedBy)
	} else {
		fmt.Printf("DEBUG: No redeemedBy provided (optional field)\n")
	}

	updateBody := map[string]interface{}{
		"findOneAndUpdate": map[string]interface{}{
			"filter": map[string]interface{}{
				"_id": voucherID,
			},
			"update": updateFields,
		},
	}

	updateURL := fmt.Sprintf("%s/voucher", h.dbClient.DataAPIURL)
	updateBytes, _ := json.Marshal(updateBody)

	fmt.Printf("DEBUG: Update URL: %s\n", updateURL)
	fmt.Printf("DEBUG: Update Body: %s\n", string(updateBytes))

	updateReq, err := http.NewRequest("POST", updateURL, bytes.NewBuffer(updateBytes))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Gagal memperbarui status voucher",
		})
	}

	updateReq.Header.Set("Content-Type", "application/json")
	updateReq.Header.Set("X-Cassandra-Token", h.dbClient.Token)

	updateResp, err := h.dbClient.Client.Do(updateReq)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Gagal memperbarui status voucher",
		})
	}
	defer updateResp.Body.Close()

	updateBodyData, _ := io.ReadAll(updateResp.Body)
	fmt.Printf("DEBUG: Update Response Status: %d\n", updateResp.StatusCode)
	fmt.Printf("DEBUG: Update Response Body: %s\n", string(updateBodyData))

	if updateResp.StatusCode != http.StatusOK && updateResp.StatusCode != http.StatusNoContent {
		return c.Status(fiber.StatusInternalServerError).JSON(models.UseVoucherResponse{
			Success: false,
			Message: "Gagal memperbarui status voucher",
		})
	}

	return c.Status(fiber.StatusOK).JSON(models.UseVoucherResponse{
		Success:     true,
		Message:     "Voucher berhasil digunakan",
		CodeVoucher: req.CodeVoucher,
		Nominal:     nominal,
	})
}

func (h *VoucherHandler) GetVoucherByCode(c *fiber.Ctx) error {
	code := c.Query("code")
	if code == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Kode voucher harus disertakan dalam query parameter",
		})
	}

	queryBody := map[string]interface{}{
		"find": map[string]interface{}{
			"filter": map[string]interface{}{
				"code_voucher": code,
			},
		},
	}

	url := fmt.Sprintf("%s/voucher", h.dbClient.DataAPIURL)
	bodyBytes, _ := json.Marshal(queryBody)

	httpReq, err := http.NewRequest("POST", url, bytes.NewBuffer(bodyBytes))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Gagal membuat request ke database",
		})
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("X-Cassandra-Token", h.dbClient.Token)

	resp, err := h.dbClient.Client.Do(httpReq)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Gagal mengakses database",
		})
	}
	defer resp.Body.Close()

	var queryResponse struct {
		Data struct {
			Documents []models.Voucher `json:"documents"`
		} `json:"data"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&queryResponse); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Gagal membaca response database",
		})
	}

	if len(queryResponse.Data.Documents) == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Voucher tidak ditemukan",
		})
	}

	voucher := queryResponse.Data.Documents[0]

	return c.JSON(fiber.Map{
		"code_voucher": voucher.CodeVoucher,
		"nominal":      voucher.Nominal,
		"used":         voucher.Used,
		"createdAt":    voucher.CreatedAt,
		"usedAt":       voucher.UsedAt,
	})
}
