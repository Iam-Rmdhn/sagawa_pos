package config

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"sync"
	"time"
)

// AstraDBClient represents a client for AstraDB REST API
type AstraDBClient struct {
	BaseURL    string
	DataAPIURL string // For Data API (Collections)
	Token      string
	Keyspace   string
	Client     *http.Client
	cache      *cache
}

// cache stores cached responses with expiry
type cache struct {
	mu   sync.RWMutex
	data map[string]*cacheEntry
}

type cacheEntry struct {
	data   []byte
	expiry time.Time
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

	// Build the Data API URL for Collections
	dataAPIURL := fmt.Sprintf("https://%s/api/json/v1/%s", endpoint, keyspace)

	// Create custom transport with longer timeouts for TLS
	transport := &http.Transport{
		DialContext: (&net.Dialer{
			Timeout:   60 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		TLSHandshakeTimeout:   60 * time.Second,
		ResponseHeaderTimeout: 60 * time.Second,
		ExpectContinueTimeout: 10 * time.Second,
		IdleConnTimeout:       90 * time.Second,
		MaxIdleConns:          100,
		MaxIdleConnsPerHost:   10,
		TLSClientConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
		},
	}

	client := &AstraDBClient{
		BaseURL:    baseURL,
		DataAPIURL: dataAPIURL,
		Token:      token,
		Keyspace:   keyspace,
		Client: &http.Client{
			Timeout:   120 * time.Second, // Overall timeout 2 minutes
			Transport: transport,
		},
		cache: &cache{
			data: make(map[string]*cacheEntry),
		},
	}

	DBClient = client
	return client, nil
}

// getFromCache retrieves data from cache if not expired
func (c *AstraDBClient) getFromCache(key string) ([]byte, bool) {
	c.cache.mu.RLock()
	defer c.cache.mu.RUnlock()

	entry, exists := c.cache.data[key]
	if !exists {
		return nil, false
	}

	if time.Now().After(entry.expiry) {
		return nil, false
	}

	return entry.data, true
}

// setCache stores data in cache with TTL
func (c *AstraDBClient) setCache(key string, data []byte, ttl time.Duration) {
	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()

	c.cache.data[key] = &cacheEntry{
		data:   data,
		expiry: time.Now().Add(ttl),
	}
}

// InvalidateCache removes a specific key from cache
func (c *AstraDBClient) InvalidateCache(key string) {
	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()
	delete(c.cache.data, key)
}

// InvalidateAllCache clears all cache
func (c *AstraDBClient) InvalidateAllCache() {
	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()
	c.cache.data = make(map[string]*cacheEntry)
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

// ExecuteQueryWithCache executes a query with caching support (for GET requests)
func (c *AstraDBClient) ExecuteQueryWithCache(method, path string, body interface{}, cacheTTL time.Duration) ([]byte, error) {
	// Only cache GET requests
	if method == "GET" && cacheTTL > 0 {
		cacheKey := path
		if cached, found := c.getFromCache(cacheKey); found {
			return cached, nil
		}
	}

	// Execute the actual query
	result, err := c.ExecuteQuery(method, path, body)
	if err != nil {
		return nil, err
	}

	// Cache the result for GET requests
	if method == "GET" && cacheTTL > 0 {
		c.setCache(path, result, cacheTTL)
	}

	return result, nil
}

// Close is a no-op for REST API client
func (c *AstraDBClient) Close() {
	// No-op for HTTP client
}

// InsertDocument inserts a document into a collection using Data API
func (c *AstraDBClient) InsertDocument(collection string, document map[string]interface{}) ([]byte, error) {
	url := fmt.Sprintf("%s/%s", c.DataAPIURL, collection)

	body := map[string]interface{}{
		"insertOne": map[string]interface{}{
			"document": document,
		},
	}

	jsonData, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request body: %v", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Token", c.Token)
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

// UpdateDocument updates a document in a collection using Data API
func (c *AstraDBClient) UpdateDocument(collection string, filter map[string]interface{}, update map[string]interface{}) ([]byte, error) {
	url := fmt.Sprintf("%s/%s", c.DataAPIURL, collection)

	body := map[string]interface{}{
		"findOneAndUpdate": map[string]interface{}{
			"filter": filter,
			"update": map[string]interface{}{
				"$set": update,
			},
			"options": map[string]interface{}{
				"returnDocument": "after",
			},
		},
	}

	jsonData, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request body: %v", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Token", c.Token)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	resp, err := c.Client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request: %v", err)
	}
	defer resp.Body.Close()

	updateRespBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("request failed with status %d: %s", resp.StatusCode, string(updateRespBody))
	}

	return updateRespBody, nil
}

// FindDocuments finds documents in a collection using Data API with filter
func (c *AstraDBClient) FindDocuments(collection string, filter map[string]interface{}, options map[string]interface{}) ([]byte, error) {
	url := fmt.Sprintf("%s/%s", c.DataAPIURL, collection)

	findBody := map[string]interface{}{
		"filter": filter,
	}

	// Add options if provided (sort, limit, skip, etc.)
	if options != nil {
		findOptions := make(map[string]interface{})

		if sort, ok := options["sort"]; ok {
			findBody["sort"] = sort
		}
		if limit, ok := options["limit"]; ok {
			findOptions["limit"] = limit
		}
		if skip, ok := options["skip"]; ok {
			findOptions["skip"] = skip
		}

		if len(findOptions) > 0 {
			findBody["options"] = findOptions
		}
	}

	body := map[string]interface{}{
		"find": findBody,
	}

	jsonData, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request body: %v", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Token", c.Token)
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
