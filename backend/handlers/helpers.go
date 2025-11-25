package handlers

import (
	"encoding/json"
	"fmt"
)

// toString converts various types into string safely
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

// extractVal unwraps nested value shapes that AstraDB REST may return.
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

// parseRowToMap normalizes various AstraDB row shapes into a simple map
func parseRowToMap(m map[string]interface{}) map[string]interface{} {
    // 1) doc_json
    if dj, ok := m["doc_json"].(string); ok && dj != "" {
        var mm map[string]interface{}
        if err := json.Unmarshal([]byte(dj), &mm); err == nil {
            return mm
        }
    }

    // 2) query_text_values
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

    // 3) columns style
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
