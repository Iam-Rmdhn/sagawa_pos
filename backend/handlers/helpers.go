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
