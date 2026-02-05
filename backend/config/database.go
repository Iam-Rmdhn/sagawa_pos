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

type AstraDBClient struct {
	BaseURL    string
	DataAPIURL string
	Token      string
	Keyspace   string
	Client     *http.Client
	cache      *cache
}

type cache struct {
	mu   sync.RWMutex
	data map[string]*cacheEntry
}

type cacheEntry struct {
	data   []byte
	expiry time.Time
}

var DBClient *AstraDBClient

func ConnectAstraDB() (*AstraDBClient, error) {
	token := os.Getenv("ASTRA_DB_TOKEN")
	endpoint := os.Getenv("ASTRA_DB_ENDPOINT")
	keyspace := os.Getenv("ASTRA_DB_KEYSPACE")

	if token == "" || endpoint == "" || keyspace == "" {
		return nil, fmt.Errorf("missing required environment variables: ASTRA_DB_TOKEN, ASTRA_DB_ENDPOINT, or ASTRA_DB_KEYSPACE")
	}

	baseURL := fmt.Sprintf("https://%s/api/rest/v2/keyspaces/%s", endpoint, keyspace)

	dataAPIURL := fmt.Sprintf("https://%s/api/json/v1/%s", endpoint, keyspace)

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
			Timeout:   120 * time.Second,
			Transport: transport,
		},
		cache: &cache{
			data: make(map[string]*cacheEntry),
		},
	}

	DBClient = client
	return client, nil
}

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

func (c *AstraDBClient) setCache(key string, data []byte, ttl time.Duration) {
	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()

	c.cache.data[key] = &cacheEntry{
		data:   data,
		expiry: time.Now().Add(ttl),
	}
}

func (c *AstraDBClient) InvalidateCache(key string) {
	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()
	delete(c.cache.data, key)
}

func (c *AstraDBClient) InvalidateAllCache() {
	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()
	c.cache.data = make(map[string]*cacheEntry)
}

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

func (c *AstraDBClient) ExecuteQueryWithCache(method, path string, body interface{}, cacheTTL time.Duration) ([]byte, error) {

	if method == "GET" && cacheTTL > 0 {
		cacheKey := path
		if cached, found := c.getFromCache(cacheKey); found {
			return cached, nil
		}
	}

	result, err := c.ExecuteQuery(method, path, body)
	if err != nil {
		return nil, err
	}

	if method == "GET" && cacheTTL > 0 {
		c.setCache(path, result, cacheTTL)
	}

	return result, nil
}

func (c *AstraDBClient) Close() {

}

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

func (c *AstraDBClient) FindDocuments(collection string, filter map[string]interface{}, options map[string]interface{}) ([]byte, error) {
	url := fmt.Sprintf("%s/%s", c.DataAPIURL, collection)

	// Build find body - AstraDB Data API structure
	// For JSON API, limit and options should be at the same level as filter
	findBody := map[string]interface{}{
		"filter": filter,
	}

	// Set default limit to 1000 (AstraDB defaults to 20 if not specified)
	limit := 1000
	if options != nil {
		if l, ok := options["limit"]; ok {
			if lInt, ok := l.(int); ok {
				limit = lInt
			}
		}
	}

	// Add options with limit - this is the correct structure for AstraDB JSON API
	findOptions := map[string]interface{}{
		"limit": limit,
	}

	// Add pagination state if provided
	if options != nil {
		if pageState, ok := options["pageState"]; ok && pageState != "" {
			findOptions["pagingState"] = pageState
			fmt.Printf("[FindDocuments] Using pageState: %s\n", pageState)
		}
	}

	findBody["options"] = findOptions
	fmt.Printf("[FindDocuments] Using limit: %d\n", limit)

	// Add sort if provided
	if options != nil {
		if sort, ok := options["sort"]; ok {
			findBody["sort"] = sort
		}
	}

	fmt.Printf("[FindDocuments] Final findBody: %+v\n", findBody)

	body := map[string]interface{}{
		"find": findBody,
	}

	jsonData, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request body: %v", err)
	}

	fmt.Printf("[FindDocuments] Request to %s: %s\n", url, string(jsonData))

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

	respStr := string(respBody)
	if len(respStr) > 800 {
		fmt.Printf("[FindDocuments] Response (first 800 chars): %s...\n", respStr[:800])
	} else {
		fmt.Printf("[FindDocuments] Full Response: %s\n", respStr)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("request failed with status %d: %s", resp.StatusCode, string(respBody))
	}

	return respBody, nil
}
