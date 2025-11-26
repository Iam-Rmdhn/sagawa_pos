package handlers

import (
	"encoding/json"
	"fmt"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/models"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type MenuHandler struct {
    dbClient *config.AstraDBClient
}

func NewMenuHandler(dbClient *config.AstraDBClient) *MenuHandler {
    return &MenuHandler{dbClient: dbClient}
}

// GetAllMenu retrieves all items from menu_makanan
func (h *MenuHandler) GetAllMenu(c *fiber.Ctx) error {
    respData, err := h.dbClient.ExecuteQuery("GET", "/menu_makanan/rows", nil)
    if err != nil {
        return c.Status(500).JSON(fiber.Map{"error": err.Error()})
    }

    // Try to unmarshal into a flexible structure and extract an array of rows
    var raw interface{}
    if err := json.Unmarshal(respData, &raw); err != nil {
        return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
    }

    // helper to convert a generic item into a map[string]interface{}
    toMap := func(item interface{}) map[string]interface{} {
        if m, ok := item.(map[string]interface{}); ok {
            return m
        }
        return nil
    }

    var rows []interface{}
    switch v := raw.(type) {
    case []interface{}:
        rows = v
    case map[string]interface{}:
        // Common AstraDB REST keys: "value", "data", "rows"
        if arr, ok := v["value"].([]interface{}); ok {
            rows = arr
        } else if arr, ok := v["data"].([]interface{}); ok {
            rows = arr
        } else if arr, ok := v["rows"].([]interface{}); ok {
            rows = arr
        } else if arr, ok := v["values"].([]interface{}); ok {
            rows = arr
        } else {
            // Nothing found - return empty list
            rows = []interface{}{}
        }
    default:
        rows = []interface{}{}
    }

    // Read optional query params to filter results
    qKemitraan := c.Query("kemitraan")
    qSubBrand := c.Query("subBrand")

    normalize := func(s string) string {
        // simple lowercase + remove non-alphanumeric
        out := ""
        for _, r := range strings.ToLower(s) {
            if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
                out += string(r)
            }
        }
        return out
    }

    // Convert rows into []models.Menu
    var menus []models.Menu
    for _, r := range rows {
        // Some Astra responses return columns array per row
        // e.g. { "columns": [{"name":"id","value":"..."}, ...] }
        if m := toMap(r); m != nil {
            // Normalize the row into a simple map[string]interface{}
            norm := parseRowToMap(m)

            // Create Menu from normalized map
            menu := models.Menu{
                ID:          toString(extractVal(norm["id"])),
                Name:        toString(extractVal(norm["name"])),
                Description: toString(extractVal(norm["description"])),
                Kemitraan:   toString(extractVal(norm["kemitraan"])),
                SubBrand:    toString(extractVal(norm["subBrand"])),
                Price:       toFloat(extractVal(norm["price"])),
                ImageURL:    toString(extractVal(norm["imageUrl"])),
                ImageID:     toString(extractVal(norm["imageId"])),
                ImageData:   toString(extractVal(norm["imageData"])),
            }
            // apply server-side filter if query provided
            if qSubBrand != "" {
                if normalize(menu.SubBrand) == normalize(qSubBrand) {
                    menus = append(menus, menu)
                }
                continue
            }
            if qKemitraan != "" {
                if strings.Contains(normalize(menu.Kemitraan), normalize(qKemitraan)) {
                    menus = append(menus, menu)
                }
                continue
            }
            menus = append(menus, menu)
        }
    }

    return c.JSON(menus)
}

// GetRaw returns the raw response body from AstraDB for debugging
func (h *MenuHandler) GetRaw(c *fiber.Ctx) error {
    respData, err := h.dbClient.ExecuteQuery("GET", "/menu_makanan/rows", nil)
    if err != nil {
        return c.Status(500).JSON(fiber.Map{"error": err.Error()})
    }
    // return raw bytes as JSON response
    c.Set("Content-Type", "application/json")
    return c.Send(respData)
}

// GetAllMenuRaw returns the raw response body from AstraDB (for debugging)
func (h *MenuHandler) GetAllMenuRaw(c *fiber.Ctx) error {
    respData, err := h.dbClient.ExecuteQuery("GET", "/menu_makanan/rows", nil)
    if err != nil {
        return c.Status(500).JSON(fiber.Map{"error": err.Error()})
    }
    // return raw bytes as string
    return c.Send(respData)
}

// GetMenu retrieves a single menu item by id
func (h *MenuHandler) GetMenu(c *fiber.Ctx) error {
    id := c.Params("id")
    path := fmt.Sprintf("/menu_makanan/%s", id)

    respData, err := h.dbClient.ExecuteQuery("GET", path, nil)
    if err != nil {
        return c.Status(404).JSON(fiber.Map{"error": "Menu item not found"})
    }

    // Try to unmarshal flexibly
    var raw interface{}
    if err := json.Unmarshal(respData, &raw); err != nil {
        return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
    }

    // extract single object from different shapes
    var obj map[string]interface{}
    if m, ok := raw.(map[string]interface{}); ok {
        // common keys
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

    // Handle columns style
    if obj != nil {
        // Normalize using the same logic as GetAllMenu
        obj = parseRowToMap(obj)

        menu := models.Menu{
            ID:          toString(extractVal(obj["id"])),
            Name:        toString(extractVal(obj["name"])),
            Description: toString(extractVal(obj["description"])),
            Kemitraan:   toString(extractVal(obj["kemitraan"])),
            SubBrand:    toString(extractVal(obj["subBrand"])),
            Price:       toFloat(extractVal(obj["price"])),
            ImageURL:    toString(extractVal(obj["imageUrl"])),
            ImageID:     toString(extractVal(obj["imageId"])),
            ImageData:   toString(extractVal(obj["imageData"])),
        }
        return c.JSON(menu)
    }

    return c.Status(404).JSON(fiber.Map{"error": "Menu item not found"})
}

// helper converters
// Note: helper functions `toString`, `extractVal`, and `parseRowToMap` are
// provided in `handlers/helpers.go` to avoid duplicate declarations.

func toFloat(v interface{}) float64 {
    if v == nil {
        return 0
    }
    switch t := v.(type) {
    case float64:
        return t
    case float32:
        return float64(t)
    case int:
        return float64(t)
    case int64:
        return float64(t)
    case string:
        var f float64
        _, err := fmt.Sscan(t, &f)
        if err == nil {
            return f
        }
    }
    return 0
}
