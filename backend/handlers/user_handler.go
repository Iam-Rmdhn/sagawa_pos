package handlers

import (
	"encoding/json"
	"fmt"
	"os"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/models"
	"strings"

	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
)

type UserHandler struct {
	dbClient *config.AstraDBClient
}

func NewUserHandler(dbClient *config.AstraDBClient) *UserHandler {
	return &UserHandler{dbClient: dbClient}
}

func (h *UserHandler) GetAllKasir(c *fiber.Ctx) error {
	respData, err := h.dbClient.ExecuteQuery("GET", "/kasir_pos/rows", nil)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var raw interface{}
	if err := json.Unmarshal(respData, &raw); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

	var rows []interface{}
	switch v := raw.(type) {
	case []interface{}:
		rows = v
	case map[string]interface{}:
		if arr, ok := v["value"].([]interface{}); ok {
			rows = arr
		} else if arr, ok := v["data"].([]interface{}); ok {
			rows = arr
		} else if arr, ok := v["rows"].([]interface{}); ok {
			rows = arr
		} else if arr, ok := v["values"].([]interface{}); ok {
			rows = arr
		} else {
			rows = []interface{}{}
		}
	default:
		rows = []interface{}{}
	}

	var kasirs []models.Kasir
	for _, r := range rows {
		if m, ok := r.(map[string]interface{}); ok {
			norm := parseRowToMap(m)
			k := models.Kasir{
				ID:               toString(extractVal(norm["id"])),
				Username:         toString(extractVal(norm["username"])),
				Kemitraan:        toString(extractVal(norm["kemitraan"])),
				Outlet:           toString(extractVal(norm["outlet"])),
				Password:         toString(extractVal(norm["password"])),
				Role:             toString(extractVal(norm["role"])),
				ProfilePhoto:     toString(extractVal(norm["profilePhoto"])),
				SubBrand:         toString(extractVal(norm["subBrand"])),
				ProfilePhotoData: toString(extractVal(norm["profilePhotoData"])),
				ProfilePhotoId:   toString(extractVal(norm["profilePhotoId"])),
				ProfilePhotoUrl:  toString(extractVal(norm["profilePhotoUrl"])),
			}
			kasirs = append(kasirs, k)
		}
	}

	return c.JSON(kasirs)
}

func (h *UserHandler) GetKasir(c *fiber.Ctx) error {
	id := strings.ToUpper(c.Params("id"))
	path := fmt.Sprintf("/kasir_pos/%s", id)

	respData, err := h.dbClient.ExecuteQuery("GET", path, nil)
	if err != nil {

		rowsResp, err2 := h.dbClient.ExecuteQuery("GET", "/kasir_pos/rows", nil)
		if err2 != nil {
			return c.Status(404).JSON(fiber.Map{"error": "Kasir not found"})
		}
		var rawAll interface{}
		if err := json.Unmarshal(rowsResp, &rawAll); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to parse fallback response"})
		}

		var arr []interface{}
		if v, ok := rawAll.([]interface{}); ok {
			arr = v
		} else if m, ok := rawAll.(map[string]interface{}); ok {
			if a, ok := m["value"].([]interface{}); ok {
				arr = a
			} else if a, ok := m["data"].([]interface{}); ok {
				arr = a
			} else if a, ok := m["rows"].([]interface{}); ok {
				arr = a
			}
		}
		for _, item := range arr {
			if mm, ok := item.(map[string]interface{}); ok {
				norm := parseRowToMap(mm)
				if toString(extractVal(norm["id"])) == "" {
					continue
				}
				if strings.EqualFold(toString(extractVal(norm["id"])), id) {

					k := models.Kasir{
						ID:               toString(extractVal(norm["id"])),
						Username:         toString(extractVal(norm["username"])),
						Kemitraan:        toString(extractVal(norm["kemitraan"])),
						Outlet:           toString(extractVal(norm["outlet"])),
						Password:         toString(extractVal(norm["password"])),
						Role:             toString(extractVal(norm["role"])),
						ProfilePhoto:     toString(extractVal(norm["profilePhoto"])),
						SubBrand:         toString(extractVal(norm["subBrand"])),
						ProfilePhotoData: toString(extractVal(norm["profilePhotoData"])),
						ProfilePhotoId:   toString(extractVal(norm["profilePhotoId"])),
						ProfilePhotoUrl:  toString(extractVal(norm["profilePhotoUrl"])),
					}
					return c.JSON(k)
				}
			}
		}
		return c.Status(404).JSON(fiber.Map{"error": "Kasir not found"})
	}

	var raw interface{}
	if err := json.Unmarshal(respData, &raw); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

	var obj map[string]interface{}
	if m, ok := raw.(map[string]interface{}); ok {
		if v, exists := m["data"]; exists {
			if arr, ok := v.([]interface{}); ok && len(arr) > 0 {
				if mm, ok := arr[0].(map[string]interface{}); ok {
					obj = mm
				}
			} else if mm, ok := v.(map[string]interface{}); ok {
				obj = mm
			}
		} else if v, exists := m["value"]; exists {
			if arr, ok := v.([]interface{}); ok && len(arr) > 0 {
				if mm, ok := arr[0].(map[string]interface{}); ok {
					obj = mm
				}
			}
		} else {
			obj = m
		}
	}

	if obj != nil {
		obj = parseRowToMap(obj)
		k := models.Kasir{
			ID:               toString(extractVal(obj["id"])),
			Username:         toString(extractVal(obj["username"])),
			Kemitraan:        toString(extractVal(obj["kemitraan"])),
			Outlet:           toString(extractVal(obj["outlet"])),
			Password:         toString(extractVal(obj["password"])),
			Role:             toString(extractVal(obj["role"])),
			ProfilePhoto:     toString(extractVal(obj["profilePhoto"])),
			SubBrand:         toString(extractVal(obj["subBrand"])),
			ProfilePhotoData: toString(extractVal(obj["profilePhotoData"])),
			ProfilePhotoId:   toString(extractVal(obj["profilePhotoId"])),
			ProfilePhotoUrl:  toString(extractVal(obj["profilePhotoUrl"])),
		}
		return c.JSON(k)
	}

	return c.Status(404).JSON(fiber.Map{"error": "Kasir not found"})
}

func (h *UserHandler) Login(c *fiber.Ctx) error {
	var body struct {
		ID       string `json:"id"`
		Password string `json:"password"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid request body"})
	}

	id := strings.ToUpper(body.ID)
	path := fmt.Sprintf("/kasir_pos/%s", id)
	respData, err := h.dbClient.ExecuteQuery("GET", path, nil)
	var obj map[string]interface{}
	if err != nil {

		rowsResp, err2 := h.dbClient.ExecuteQuery("GET", "/kasir_pos/rows", nil)
		if err2 != nil {
			return c.Status(401).JSON(fiber.Map{"error": "invalid id or password"})
		}
		var rawAll interface{}
		if err := json.Unmarshal(rowsResp, &rawAll); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to parse fallback response"})
		}
		var found map[string]interface{}
		var arr []interface{}
		if v, ok := rawAll.([]interface{}); ok {
			arr = v
		} else if m, ok := rawAll.(map[string]interface{}); ok {
			if a, ok := m["value"].([]interface{}); ok {
				arr = a
			} else if a, ok := m["data"].([]interface{}); ok {
				arr = a
			} else if a, ok := m["rows"].([]interface{}); ok {
				arr = a
			}
		}
		for _, item := range arr {
			if mm, ok := item.(map[string]interface{}); ok {
				norm := parseRowToMap(mm)
				if strings.EqualFold(toString(extractVal(norm["id"])), id) {
					found = norm
					break
				}
			}
		}
		if found == nil {
			return c.Status(401).JSON(fiber.Map{"error": "invalid id or password"})
		}

		obj = found
	} else {
		var raw interface{}
		if err := json.Unmarshal(respData, &raw); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
		}

		if m, ok := raw.(map[string]interface{}); ok {
			if v, exists := m["data"]; exists {
				if arr, ok := v.([]interface{}); ok && len(arr) > 0 {
					if mm, ok := arr[0].(map[string]interface{}); ok {
						obj = mm
					}
				} else if mm, ok := v.(map[string]interface{}); ok {
					obj = mm
				}
			} else if v, exists := m["value"]; exists {
				if arr, ok := v.([]interface{}); ok && len(arr) > 0 {
					if mm, ok := arr[0].(map[string]interface{}); ok {
						obj = mm
					}
				}
			} else {
				obj = m
			}
		}
	}

	if obj == nil {
		return c.Status(401).JSON(fiber.Map{"error": "invalid id or password"})
	}

	obj = parseRowToMap(obj)
	storedPassword := toString(extractVal(obj["password"]))

	if os.Getenv("DEV_DEBUG_LOGIN") != "" {
		fmt.Printf("[DEV_DEBUG_LOGIN] fetched kasir obj=%v\n", obj)
		fmt.Printf("[DEV_DEBUG_LOGIN] storedPassword='%s' requestPassword='%s'\n", storedPassword, body.Password)
	}

	reqPwd := strings.TrimSpace(body.Password)
	storedPwdTrim := strings.TrimSpace(storedPassword)

	if strings.HasPrefix(storedPwdTrim, "$2") {

		if err := bcrypt.CompareHashAndPassword([]byte(storedPwdTrim), []byte(reqPwd)); err != nil {
			return c.Status(401).JSON(fiber.Map{"error": "invalid id or password"})
		}
	} else {

		if storedPwdTrim != reqPwd {
			return c.Status(401).JSON(fiber.Map{"error": "invalid id or password"})
		}
	}

	k := models.Kasir{
		ID:               toString(extractVal(obj["id"])),
		Username:         toString(extractVal(obj["username"])),
		Kemitraan:        toString(extractVal(obj["kemitraan"])),
		Outlet:           toString(extractVal(obj["outlet"])),
		Role:             toString(extractVal(obj["role"])),
		ProfilePhoto:     toString(extractVal(obj["profilePhoto"])),
		SubBrand:         toString(extractVal(obj["subBrand"])),
		ProfilePhotoData: toString(extractVal(obj["profilePhotoData"])),
		ProfilePhotoId:   toString(extractVal(obj["profilePhotoId"])),
		ProfilePhotoUrl:  toString(extractVal(obj["profilePhotoUrl"])),
	}

	return c.JSON(k)
}

func (h *UserHandler) UpdateProfile(c *fiber.Ctx) error {
	id := strings.ToUpper(c.Params("id"))

	var body struct {
		Username         string `json:"username"`
		Kemitraan        string `json:"kemitraan"`
		Outlet           string `json:"outlet"`
		SubBrand         string `json:"subBrand"`
		ProfilePhotoData string `json:"profilePhotoData"`
	}

	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid request body"})
	}

	updateData := make(map[string]interface{})
	if body.Username != "" {
		updateData["username"] = body.Username
	}
	if body.Kemitraan != "" {
		updateData["kemitraan"] = body.Kemitraan
	}
	if body.Outlet != "" {
		updateData["outlet"] = body.Outlet
	}
	if body.SubBrand != "" {
		updateData["subBrand"] = body.SubBrand
	}
	if body.ProfilePhotoData != "" {
		updateData["profilePhotoData"] = body.ProfilePhotoData
	}

	if len(updateData) == 0 {
		return c.Status(400).JSON(fiber.Map{"error": "no fields to update"})
	}

	filter := map[string]interface{}{
		"id": id,
	}

	fmt.Printf("[UpdateProfile] Updating kasir %s with data: %+v\n", id, updateData)

	respData, err := h.dbClient.UpdateDocument("kasir_pos", filter, updateData)
	if err != nil {
		fmt.Printf("[UpdateProfile] Error: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	fmt.Printf("[UpdateProfile] Response: %s\n", string(respData))

	var result map[string]interface{}
	if err := json.Unmarshal(respData, &result); err != nil {
		return c.JSON(fiber.Map{"message": "profile updated"})
	}

	var obj map[string]interface{}
	if data, ok := result["data"].(map[string]interface{}); ok {
		if doc, ok := data["document"].(map[string]interface{}); ok {
			obj = doc
		}
	}

	if obj != nil {
		k := models.Kasir{
			ID:               toString(extractVal(obj["id"])),
			Username:         toString(extractVal(obj["username"])),
			Kemitraan:        toString(extractVal(obj["kemitraan"])),
			Outlet:           toString(extractVal(obj["outlet"])),
			Role:             toString(extractVal(obj["role"])),
			ProfilePhoto:     toString(extractVal(obj["profilePhoto"])),
			SubBrand:         toString(extractVal(obj["subBrand"])),
			ProfilePhotoData: toString(extractVal(obj["profilePhotoData"])),
			ProfilePhotoId:   toString(extractVal(obj["profilePhotoId"])),
			ProfilePhotoUrl:  toString(extractVal(obj["profilePhotoUrl"])),
		}
		return c.JSON(k)
	}

	return c.JSON(fiber.Map{"message": "profile updated"})
}

func (h *UserHandler) SetPassword(c *fiber.Ctx) error {

	if os.Getenv("DEV_ALLOW_PASSWORD_UPDATE") == "" {
		return c.Status(403).JSON(fiber.Map{"error": "forbidden"})
	}

	id := strings.ToUpper(c.Params("id"))
	var body struct {
		Password string `json:"password"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "invalid request body"})
	}

	path := fmt.Sprintf("/kasir_pos/%s", id)

	hashed, err := bcrypt.GenerateFromPassword([]byte(body.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "failed to hash password"})
	}
	putBody := map[string]interface{}{
		"password": string(hashed),
	}

	if _, err := h.dbClient.ExecuteQuery("PUT", path, putBody); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "password updated"})
}
