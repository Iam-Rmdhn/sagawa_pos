package handlers

import (
	"encoding/json"
	"fmt"
	"math"
)

const TAX_RATE = 0.10

func CalculateTax(taxBase float64) float64 {
	return taxBase * TAX_RATE
}

func CalculateTotal(taxBase float64) float64 {
	return taxBase + CalculateTax(taxBase)
}

func CalculateSubtotalAfterPotongan(subtotal, potongan float64) float64 {
	result := subtotal - potongan
	if result < 0 {
		return 0
	}
	return result
}

func CalculateAfterTax(subtotal, potongan float64) float64 {
	subtotalAfterPotongan := CalculateSubtotalAfterPotongan(subtotal, potongan)
	return CalculateTotal(subtotalAfterPotongan)
}

func RoundToNearestHundred(value float64) float64 {
	return math.Round(value/100) * 100
}

func toString(v interface{}) string {
	if v == nil {
		return ""
	}
	switch t := v.(type) {
	case string:
		return t
	case []byte:
		return string(t)
	default:
		return fmt.Sprintf("%v", t)
	}
}

func resolveKemitraan(m map[string]interface{}) string {
	if k := toString(extractVal(m["kemitraan"])); k != "" {
		return k
	}
	return toString(extractVal(m["restaurant"]))
}

func resolveMenuID(m map[string]interface{}) string {
	for _, key := range []string{"id", "_id"} {
		if v := toString(extractVal(m[key])); v != "" {
			return v
		}
	}
	return ""
}

func resolveMenuName(m map[string]interface{}) string {
	if name := toString(extractVal(m["name"])); name != "" {
		return name
	}
	return toString(extractVal(m["title"]))
}

func resolveSubBrand(m map[string]interface{}) string {
	for _, key := range []string{"subBrand", "sub_brand", "subbrand"} {
		if v := toString(extractVal(m[key])); v != "" {
			return v
		}
	}
	return ""
}

func resolveKategori(m map[string]interface{}) string {
	if k := toString(extractVal(m["kategori"])); k != "" {
		return k
	}
	return toString(extractVal(m["category"]))
}

func resolveImageURL(m map[string]interface{}) string {
	if imageURL := toString(extractVal(m["imageUrl"])); imageURL != "" {
		return imageURL
	}
	return toString(extractVal(m["image_url"]))
}

func resolveImageID(m map[string]interface{}) string {
	if imageID := toString(extractVal(m["imageId"])); imageID != "" {
		return imageID
	}
	return toString(extractVal(m["image_id"]))
}

func resolveImageData(m map[string]interface{}) string {
	if imageData := toString(extractVal(m["imageData"])); imageData != "" {
		return imageData
	}
	return toString(extractVal(m["image_data"]))
}

func extractVal(v interface{}) interface{} {
	if v == nil {
		return nil
	}
	if m, ok := v.(map[string]interface{}); ok {
		if inner, exists := m["value"]; exists {
			return extractVal(inner)
		}
		return m
	}
	if a, ok := v.([]interface{}); ok {
		if len(a) == 1 {
			return extractVal(a[0])
		}
		return a
	}
	return v
}

func parseRowToMap(m map[string]interface{}) map[string]interface{} {

	if dj, ok := m["doc_json"].(string); ok && dj != "" {
		var mm map[string]interface{}
		if err := json.Unmarshal([]byte(dj), &mm); err == nil {
			return mm
		}
	}

	if qtv, ok := m["query_text_values"].([]interface{}); ok && len(qtv) > 0 {
		out := map[string]interface{}{}
		for _, item := range qtv {
			if im, ok := item.(map[string]interface{}); ok {
				key, _ := im["key"].(string)
				if val, exists := im["value"]; exists {
					out[key] = val
				}
			}
		}
		return out
	}

	if cols, ok := m["columns"].([]interface{}); ok && len(cols) > 0 {
		out := map[string]interface{}{}
		for _, ci := range cols {
			if cm, ok := ci.(map[string]interface{}); ok {
				name, _ := cm["name"].(string)
				if val, exists := cm["value"]; exists {
					out[name] = extractVal(val)
				}
			}
		}
		return out
	}

	return m
}
