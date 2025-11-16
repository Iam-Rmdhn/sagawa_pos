package config

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

// AstraDBClient represents a client for AstraDB REST API
type AstraDBClient struct {
	BaseURL  string
	Token    string
	Keyspace string
	Client   *http.Client
}

var DBClient *AstraDBClient

// ConnectAstraDB initializes the AstraDB REST API client
func ConnectAstraDB() (*AstraDBClient, error) {
	token := os.Getenv("ASTRA_DB_TOKEN")
	endpoint := os.Getenv("ASTRA_DB_ENDPOINT")
	keyspace := os.Getenv("ASTRA_DB_KEYSPACE")

	if token == "" || endpoint == "" || keyspace == "" {
		return nil, fmt.Errorf("missing required environment variables: ASTRA_DB_TOKEN, ASTRA_DB_ENDPOINT, or ASTRA_DB_KEYSPACE")
	}

	// Build the REST API base URL
	baseURL := fmt.Sprintf("https://%s/api/rest/v2/keyspaces/%s", endpoint, keyspace)

	client := &AstraDBClient{
		BaseURL:  baseURL,
		Token:    token,
		Keyspace: keyspace,
		Client:   &http.Client{},
	}

	DBClient = client
	return client, nil
}

// ExecuteQuery executes a query against AstraDB REST API
func (c *AstraDBClient) ExecuteQuery(method, path string, body interface{}) ([]byte, error) {
	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %v", err)
		}
		reqBody = bytes.NewBuffer(jsonData)
	}

	url := c.BaseURL + path
	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("X-Cassandra-Token", c.Token)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := c.Client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request: %v", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("request failed with status %d: %s", resp.StatusCode, string(respBody))
	}

	return respBody, nil
}

// Close is a no-op for REST API client
func (c *AstraDBClient) Close() {
	// No-op for HTTP client
}
