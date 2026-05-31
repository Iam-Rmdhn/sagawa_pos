package config

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

type AstraDBClient struct {
	BaseURL        string
	DataAPIURL     string
	Token          string
	Keyspace       string
	Client         *http.Client
	cache          *cache
	redisClient    *redis.Client
	redisKeyPrefix string
	paginatedMu    sync.Mutex
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

const defaultRedisKeyPrefix = "sagawa_pos"

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

	client.configureRedis()

	DBClient = client
	return client, nil
}

func (c *AstraDBClient) configureRedis() {
	if os.Getenv("REDIS_ENABLED") != "true" {
		fmt.Println("[Redis] Disabled. Using in-memory cache.")
		return
	}

	addr := os.Getenv("REDIS_ADDR")
	if addr == "" {
		addr = "localhost:6379"
	}

	db := 0
	if rawDB := os.Getenv("REDIS_DB"); rawDB != "" {
		parsedDB, err := strconv.Atoi(rawDB)
		if err != nil {
			fmt.Printf("[Redis] Invalid REDIS_DB value %q. Using DB 0.\n", rawDB)
		} else {
			db = parsedDB
		}
	}

	keyPrefix := os.Getenv("REDIS_KEY_PREFIX")
	if keyPrefix == "" {
		keyPrefix = defaultRedisKeyPrefix
	}

	redisClient := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: os.Getenv("REDIS_PASSWORD"),
		DB:       db,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	if err := redisClient.Ping(ctx).Err(); err != nil {
		fmt.Printf("[Redis] Connection failed: %v. Falling back to in-memory cache.\n", err)
		_ = redisClient.Close()
		return
	}

	c.redisClient = redisClient
	c.redisKeyPrefix = keyPrefix
	fmt.Printf("[Redis] Connected to %s with key prefix %q.\n", addr, keyPrefix)
}

func (c *AstraDBClient) redisCacheKey(key string) string {
	prefix := c.redisKeyPrefix
	if prefix == "" {
		prefix = defaultRedisKeyPrefix
	}

	return fmt.Sprintf("%s:cache:%s", prefix, key)
}

func (c *AstraDBClient) getFromCache(key string) ([]byte, bool) {
	if c.redisClient != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		cached, err := c.redisClient.Get(ctx, c.redisCacheKey(key)).Bytes()
		if err == nil {
			return cached, true
		}
		if err != redis.Nil {
			fmt.Printf("[Redis] Failed to get cache key %q: %v\n", key, err)
		}
	}

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
	if c.redisClient != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := c.redisClient.Set(ctx, c.redisCacheKey(key), data, ttl).Err(); err != nil {
			fmt.Printf("[Redis] Failed to set cache key %q: %v\n", key, err)
		}
	}

	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()

	c.cache.data[key] = &cacheEntry{
		data:   data,
		expiry: time.Now().Add(ttl),
	}
}

func (c *AstraDBClient) InvalidateCache(key string) {
	if c.redisClient != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := c.redisClient.Del(ctx, c.redisCacheKey(key)).Err(); err != nil {
			fmt.Printf("[Redis] Failed to delete cache key %q: %v\n", key, err)
		}
	}

	c.cache.mu.Lock()
	defer c.cache.mu.Unlock()
	delete(c.cache.data, key)
}

func (c *AstraDBClient) InvalidateAllCache() {
	if c.redisClient != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		iter := c.redisClient.Scan(ctx, 0, c.redisCacheKey("*"), 0).Iterator()
		for iter.Next(ctx) {
			if err := c.redisClient.Del(ctx, iter.Val()).Err(); err != nil {
				fmt.Printf("[Redis] Failed to delete cache key %q: %v\n", iter.Val(), err)
			}
		}
		if err := iter.Err(); err != nil {
			fmt.Printf("[Redis] Failed to scan cache keys: %v\n", err)
		}
	}

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

func PaginatedRowsCacheKey(path string, pageSize int) string {
	if pageSize <= 0 {
		pageSize = 100
	}
	return fmt.Sprintf("%s?all-pages=true&page-size=%d", path, pageSize)
}

func (c *AstraDBClient) ExecutePaginatedRowsWithCache(path string, pageSize int, cacheTTL time.Duration) ([]byte, error) {
	if pageSize <= 0 {
		pageSize = 100
	}

	cacheKey := PaginatedRowsCacheKey(path, pageSize)
	if cacheTTL > 0 {
		if cached, found := c.getFromCache(cacheKey); found {
			return cached, nil
		}
	}

	// Serialize cold rebuilds so a burst of concurrent requests (e.g. several
	// cashiers opening the menu right after a cache invalidation) triggers a
	// single full pagination pass instead of one per request. Late arrivals
	// re-check the cache after acquiring the lock and reuse the warmed value.
	c.paginatedMu.Lock()
	defer c.paginatedMu.Unlock()

	if cacheTTL > 0 {
		if cached, found := c.getFromCache(cacheKey); found {
			return cached, nil
		}
	}

	return c.fetchAndCachePaginatedRows(path, pageSize, cacheTTL)
}

// RefreshPaginatedRows forces a full pagination pass and repopulates the cache,
// regardless of any existing cached value. Use it to warm the cache proactively
// (startup, version change) so user-facing requests never pay the cold cost.
func (c *AstraDBClient) RefreshPaginatedRows(path string, pageSize int, cacheTTL time.Duration) ([]byte, error) {
	if pageSize <= 0 {
		pageSize = 100
	}

	c.paginatedMu.Lock()
	defer c.paginatedMu.Unlock()

	return c.fetchAndCachePaginatedRows(path, pageSize, cacheTTL)
}

func (c *AstraDBClient) fetchAndCachePaginatedRows(path string, pageSize int, cacheTTL time.Duration) ([]byte, error) {
	cacheKey := PaginatedRowsCacheKey(path, pageSize)

	var allRows []interface{}
	pageState := ""
	seenPageStates := make(map[string]bool)

	for {
		values := url.Values{}
		values.Set("page-size", strconv.Itoa(pageSize))
		if pageState != "" {
			values.Set("page-state", pageState)
		}

		pagePath := path + "?" + values.Encode()
		respData, err := c.ExecuteQuery("GET", pagePath, nil)
		if err != nil {
			return nil, err
		}

		var raw interface{}
		if err := json.Unmarshal(respData, &raw); err != nil {
			return nil, fmt.Errorf("failed to parse paginated response: %v", err)
		}

		rows, nextPageState := extractRowsAndPageState(raw)
		allRows = append(allRows, rows...)

		if nextPageState == "" || seenPageStates[nextPageState] {
			break
		}

		seenPageStates[nextPageState] = true
		pageState = nextPageState
	}

	result, err := json.Marshal(map[string]interface{}{
		"count": len(allRows),
		"data":  allRows,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to marshal paginated response: %v", err)
	}

	if cacheTTL > 0 {
		c.setCache(cacheKey, result, cacheTTL)
	}

	return result, nil
}

func extractRowsAndPageState(raw interface{}) ([]interface{}, string) {
	switch v := raw.(type) {
	case []interface{}:
		return v, ""
	case map[string]interface{}:
		rows := []interface{}{}
		for _, key := range []string{"data", "value", "rows", "values"} {
			if arr, ok := v[key].([]interface{}); ok {
				rows = arr
				break
			}
		}

		pageState := ""
		if val, ok := v["pageState"]; ok {
			pageState = fmt.Sprintf("%v", val)
		}

		return rows, pageState
	default:
		return []interface{}{}, ""
	}
}

func (c *AstraDBClient) Close() {
	if c.redisClient != nil {
		_ = c.redisClient.Close()
	}
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
	return c.findDocuments(collection, filter, options, true)
}

func (c *AstraDBClient) FindDocumentsQuiet(collection string, filter map[string]interface{}, options map[string]interface{}) ([]byte, error) {
	return c.findDocuments(collection, filter, options, false)
}

func (c *AstraDBClient) findDocuments(collection string, filter map[string]interface{}, options map[string]interface{}, debug bool) ([]byte, error) {
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
			if debug {
				fmt.Printf("[FindDocuments] Using pageState: %s\n", pageState)
			}
		}
	}

	findBody["options"] = findOptions
	if debug {
		fmt.Printf("[FindDocuments] Using limit: %d\n", limit)
	}

	// Add sort if provided
	if options != nil {
		if sort, ok := options["sort"]; ok {
			findBody["sort"] = sort
		}
	}

	if debug {
		fmt.Printf("[FindDocuments] Final findBody: %+v\n", findBody)
	}

	body := map[string]interface{}{
		"find": findBody,
	}

	jsonData, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request body: %v", err)
	}

	if debug {
		fmt.Printf("[FindDocuments] Request to %s: %s\n", url, string(jsonData))
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

	if debug {
		respStr := string(respBody)
		if len(respStr) > 800 {
			fmt.Printf("[FindDocuments] Response (first 800 chars): %s...\n", respStr[:800])
		} else {
			fmt.Printf("[FindDocuments] Full Response: %s\n", respStr)
		}
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("request failed with status %d: %s", resp.StatusCode, string(respBody))
	}

	return respBody, nil
}
