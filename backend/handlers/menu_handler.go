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

const menuCacheTTL = 1 * time.Hour
const menuSyncCheckInterval = 10 * time.Second
const menuRowsPath = "/menu_makanan/rows"
const menuRowsPageSize = 1000

func (h *MenuHandler) invalidateMenuRowsCache() {
	h.dbClient.InvalidateCache(menuRowsPath)
	h.dbClient.InvalidateCache(config.PaginatedRowsCacheKey(menuRowsPath, menuRowsPageSize))
}

// warmMenuRowsCache forces a full pagination pass and repopulates the cache so
// the next user-facing request reads a warm cache instead of paying the cold
// full-table fetch (which is what was causing the app to time out on load).
func (h *MenuHandler) warmMenuRowsCache() {
	if _, err := h.dbClient.RefreshPaginatedRows(menuRowsPath, menuRowsPageSize, menuCacheTTL); err != nil {
		fmt.Printf("[MenuSync] Failed to warm menu cache: %v\n", err)
	}
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
	go h.warmMenuRowsCache()
	fmt.Printf("[MenuSync] Menu cache refresh scheduled at version %d\n", version)
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
				Kemitraan:   resolveKemitraan(norm),
				SubBrand:    resolveSubBrand(norm),
				Kategori:    resolveKategori(norm),
				Price:       toFloat(extractVal(norm["price"])),
				Stock:       menuToInt(extractFirstVal(norm, "stock")),
				IsActive:    toBoolDefault(extractFirstVal(norm, "is_active", "isEnabled", "is_enabled"), true),
				IsEnabled:   toBoolDefault(extractFirstVal(norm, "isEnabled", "is_active", "is_enabled"), true),
				IsBestSeller: toBoolDefault(
					extractFirstVal(norm, "isBestSeller", "is_best_seller"),
					false,
				),
				ImageURL:  toString(extractVal(norm["imageUrl"])),
				ImageID:   toString(extractVal(norm["imageId"])),
				ImageData: toString(extractVal(norm["imageData"])),
			}

			if qSubBrand != "" {
				itemSubBrand := normalize(menu.SubBrand)
				querySubBrand := normalize(qSubBrand)
				matchesSubBrand := itemSubBrand == querySubBrand
				matchesLegacyItem := itemSubBrand == "" && qKemitraan != "" && menuMatchesKemitraan(menu.Kemitraan, qKemitraan)

				if matchesSubBrand || matchesLegacyItem {
					menus = append(menus, menu)
				}
				continue
			}
			if qKemitraan != "" {
				if menuMatchesKemitraan(menu.Kemitraan, qKemitraan) {
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
			Kemitraan:   resolveKemitraan(obj),
			SubBrand:    resolveSubBrand(obj),
			Kategori:    resolveKategori(obj),
			Price:       toFloat(extractVal(obj["price"])),
			Stock:       menuToInt(extractFirstVal(obj, "stock")),
			IsActive:    toBoolDefault(extractFirstVal(obj, "is_active", "isEnabled", "is_enabled"), true),
			IsEnabled:   toBoolDefault(extractFirstVal(obj, "isEnabled", "is_active", "is_enabled"), true),
			IsBestSeller: toBoolDefault(
				extractFirstVal(obj, "isBestSeller", "is_best_seller"),
				false,
			),
			ImageURL:  toString(extractVal(obj["imageUrl"])),
			ImageID:   toString(extractVal(obj["imageId"])),
			ImageData: toString(extractVal(obj["imageData"])),
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

			itemKemitraan := resolveKemitraan(norm)
			itemSubBrand := resolveSubBrand(norm)
			itemKategori := resolveKategori(norm)

			if itemKategori == "" {
				continue
			}

			if qSubBrand != "" {
				matchesSubBrand := normalize(itemSubBrand) == normalize(qSubBrand)
				matchesLegacyItem := normalize(itemSubBrand) == "" && qKemitraan != "" && menuMatchesKemitraan(itemKemitraan, qKemitraan)
				if !matchesSubBrand && !matchesLegacyItem {
					continue
				}
			} else if qKemitraan != "" {

				if !menuMatchesKemitraan(itemKemitraan, qKemitraan) {
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

func extractFirstVal(m map[string]interface{}, keys ...string) interface{} {
	for _, key := range keys {
		if val, ok := m[key]; ok {
			return extractVal(val)
		}
	}
	return nil
}

func menuToInt(v interface{}) int {
	return int(toFloat(v))
}

func menuMatchesKemitraan(itemKemitraan, queryKemitraan string) bool {
	item := normalizeMenuFilter(itemKemitraan)
	query := normalizeMenuFilter(queryKemitraan)
	if item == "" || query == "" {
		return false
	}
	return strings.Contains(item, query) || strings.Contains(query, item)
}

func normalizeMenuFilter(s string) string {
	out := ""
	for _, r := range strings.ToLower(s) {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			out += string(r)
		}
	}
	return out
}

func toBoolDefault(v interface{}, fallback bool) bool {
	if v == nil {
		return fallback
	}
	switch t := v.(type) {
	case bool:
		return t
	case string:
		switch strings.ToLower(strings.TrimSpace(t)) {
		case "true", "1", "yes", "y", "active", "enabled":
			return true
		case "false", "0", "no", "n", "inactive", "disabled":
			return false
		}
	case float64:
		return t != 0
	case float32:
		return t != 0
	case int:
		return t != 0
	case int64:
		return t != 0
	}
	return fallback
}
