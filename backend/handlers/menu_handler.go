package handlers

import (
	"encoding/json"
	"fmt"
	"sagawa_pos_backend/config"
	"sagawa_pos_backend/models"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
)

type MenuHandler struct {
	dbClient             *config.AstraDBClient
	menuVersionMutex     sync.Mutex
	lastMenuVersion      int64
	lastMenuVersionCheck time.Time
}

func NewMenuHandler(dbClient *config.AstraDBClient) *MenuHandler {
	return &MenuHandler{dbClient: dbClient}
}

const menuCacheTTL = 5 * time.Minute
const menuSyncCheckInterval = 10 * time.Second
const menuRowsPath = "/menu_makanan/rows"
const menuRowsPageSize = 100

func (h *MenuHandler) invalidateMenuRowsCache() {
	h.dbClient.InvalidateCache(menuRowsPath)
	h.dbClient.InvalidateCache(config.PaginatedRowsCacheKey(menuRowsPath, menuRowsPageSize))
}

func (h *MenuHandler) refreshMenuCacheIfVersionChanged() {
	h.menuVersionMutex.Lock()
	if time.Since(h.lastMenuVersionCheck) < menuSyncCheckInterval {
		h.menuVersionMutex.Unlock()
		return
	}
	h.lastMenuVersionCheck = time.Now()
	h.menuVersionMutex.Unlock()

	respData, err := h.dbClient.FindDocumentsQuiet(
		"menu_sync",
		map[string]interface{}{"id": "menu_sync"},
		map[string]interface{}{"limit": 1},
	)
	if err != nil {
		fmt.Printf("[MenuSync] Failed to fetch menu sync state: %v\n", err)
		return
	}

	var raw interface{}
	if err := json.Unmarshal(respData, &raw); err != nil {
		fmt.Printf("[MenuSync] Failed to parse menu sync state: %v\n", err)
		return
	}

	version := extractMenuSyncVersion(raw)
	if version == 0 {
		return
	}

	h.menuVersionMutex.Lock()
	defer h.menuVersionMutex.Unlock()

	if version == h.lastMenuVersion {
		return
	}

	h.lastMenuVersion = version
	h.invalidateMenuRowsCache()
	fmt.Printf("[MenuSync] Menu cache invalidated at version %d\n", version)
}

func extractMenuSyncVersion(raw interface{}) int64 {
	switch v := raw.(type) {
	case map[string]interface{}:
		if data, ok := v["data"]; ok {
			if version := extractMenuSyncVersion(data); version > 0 {
				return version
			}
		}
		if docs, ok := v["documents"]; ok {
			if version := extractMenuSyncVersion(docs); version > 0 {
				return version
			}
		}
		if doc, ok := v["document"]; ok {
			if version := extractMenuSyncVersion(doc); version > 0 {
				return version
			}
		}
		if version, ok := v["version"]; ok {
			return int64(toFloat(extractVal(version)))
		}
	case []interface{}:
		for _, item := range v {
			if version := extractMenuSyncVersion(item); version > 0 {
				return version
			}
		}
	}

	return 0
}

func (h *MenuHandler) GetAllMenu(c *fiber.Ctx) error {
	h.refreshMenuCacheIfVersionChanged()

	respData, err := h.dbClient.ExecutePaginatedRowsWithCache(menuRowsPath, menuRowsPageSize, menuCacheTTL)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var raw interface{}
	if err := json.Unmarshal(respData, &raw); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

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

	qKemitraan := c.Query("kemitraan")
	qSubBrand := c.Query("subBrand")

	normalize := func(s string) string {

		out := ""
		for _, r := range strings.ToLower(s) {
			if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
				out += string(r)
			}
		}
		return out
	}

	var menus []models.Menu
	for _, r := range rows {

		if m := toMap(r); m != nil {

			norm := parseRowToMap(m)

			menu := models.Menu{
				ID:          toString(extractVal(norm["id"])),
				Name:        toString(extractVal(norm["name"])),
				Description: toString(extractVal(norm["description"])),
				Kemitraan:   toString(extractVal(norm["kemitraan"])),
				SubBrand:    toString(extractVal(norm["subBrand"])),
				Kategori:    toString(extractVal(norm["kategori"])),
				Price:       toFloat(extractVal(norm["price"])),
				ImageURL:    toString(extractVal(norm["imageUrl"])),
				ImageID:     toString(extractVal(norm["imageId"])),
				ImageData:   toString(extractVal(norm["imageData"])),
			}

			if qSubBrand != "" {
				if normalize(menu.SubBrand) == normalize(qSubBrand) {
					menus = append(menus, menu)
				}
				continue
			}
			if qKemitraan != "" {
				itemKemitraan := normalize(menu.Kemitraan)
				queryKemitraan := normalize(qKemitraan)
				if strings.Contains(itemKemitraan, queryKemitraan) ||
					strings.Contains(queryKemitraan, itemKemitraan) {
					menus = append(menus, menu)
				}
				continue
			}
			menus = append(menus, menu)
		}
	}

	return c.JSON(menus)
}

func (h *MenuHandler) GetRaw(c *fiber.Ctx) error {
	h.refreshMenuCacheIfVersionChanged()

	respData, err := h.dbClient.ExecutePaginatedRowsWithCache(menuRowsPath, menuRowsPageSize, menuCacheTTL)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	c.Set("Content-Type", "application/json")
	return c.Send(respData)
}

func (h *MenuHandler) GetAllMenuRaw(c *fiber.Ctx) error {
	h.refreshMenuCacheIfVersionChanged()

	respData, err := h.dbClient.ExecutePaginatedRowsWithCache(menuRowsPath, menuRowsPageSize, menuCacheTTL)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Send(respData)
}

func (h *MenuHandler) RefreshMenuCache(c *fiber.Ctx) error {
	h.invalidateMenuRowsCache()
	return c.JSON(fiber.Map{"message": "Menu cache refreshed"})
}

func (h *MenuHandler) GetMenuSync(c *fiber.Ctx) error {
	respData, err := h.dbClient.FindDocumentsQuiet(
		"menu_sync",
		map[string]interface{}{"id": "menu_sync"},
		map[string]interface{}{"limit": 1},
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var raw interface{}
	if err := json.Unmarshal(respData, &raw); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

	version := extractMenuSyncVersion(raw)
	return c.JSON(fiber.Map{"version": version})
}

func (h *MenuHandler) GetMenu(c *fiber.Ctx) error {
	id := c.Params("id")
	path := fmt.Sprintf("/menu_makanan/%s", id)

	respData, err := h.dbClient.ExecuteQuery("GET", path, nil)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Menu item not found"})
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

		menu := models.Menu{
			ID:          toString(extractVal(obj["id"])),
			Name:        toString(extractVal(obj["name"])),
			Description: toString(extractVal(obj["description"])),
			Kemitraan:   toString(extractVal(obj["kemitraan"])),
			SubBrand:    toString(extractVal(obj["subBrand"])),
			Kategori:    toString(extractVal(obj["kategori"])),
			Price:       toFloat(extractVal(obj["price"])),
			ImageURL:    toString(extractVal(obj["imageUrl"])),
			ImageID:     toString(extractVal(obj["imageId"])),
			ImageData:   toString(extractVal(obj["imageData"])),
		}
		return c.JSON(menu)
	}

	return c.Status(404).JSON(fiber.Map{"error": "Menu item not found"})
}

func (h *MenuHandler) GetCategories(c *fiber.Ctx) error {
	qKemitraan := c.Query("kemitraan")
	qSubBrand := c.Query("subBrand")
	h.refreshMenuCacheIfVersionChanged()

	respData, err := h.dbClient.ExecutePaginatedRowsWithCache(menuRowsPath, menuRowsPageSize, menuCacheTTL)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var raw interface{}
	if err := json.Unmarshal(respData, &raw); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse response"})
	}

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

	normalize := func(s string) string {
		out := ""
		for _, r := range strings.ToLower(s) {
			if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
				out += string(r)
			}
		}
		return out
	}

	categorySet := make(map[string]bool)
	var categories []string

	for _, r := range rows {
		if m := toMap(r); m != nil {
			norm := parseRowToMap(m)

			itemKemitraan := toString(extractVal(norm["kemitraan"]))
			itemSubBrand := toString(extractVal(norm["subBrand"]))
			itemKategori := toString(extractVal(norm["kategori"]))

			if itemKategori == "" {
				continue
			}

			if qSubBrand != "" {
				if normalize(itemSubBrand) != normalize(qSubBrand) {
					continue
				}
			} else if qKemitraan != "" {

				if !strings.Contains(normalize(itemKemitraan), normalize(qKemitraan)) &&
					!strings.Contains(normalize(qKemitraan), normalize(itemKemitraan)) {
					continue
				}
			}

			if !categorySet[itemKategori] {
				categorySet[itemKategori] = true
				categories = append(categories, itemKategori)
			}
		}
	}

	return c.JSON(fiber.Map{
		"categories": categories,
		"count":      len(categories),
		"kemitraan":  qKemitraan,
		"subBrand":   qSubBrand,
	})
}

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
