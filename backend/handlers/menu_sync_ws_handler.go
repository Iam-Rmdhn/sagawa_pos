package handlers

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"sagawa_pos_backend/config"

	"github.com/gofiber/contrib/websocket"
)

const menuSyncWebSocketPollInterval = 5 * time.Second

type MenuSyncWebSocketHub struct {
	dbClient *config.AstraDBClient

	mu          sync.Mutex
	clients     map[*websocket.Conn]bool
	lastVersion int64
	startOnce   sync.Once
}

type menuSyncWebSocketEvent struct {
	Type      string `json:"type"`
	Version   int64  `json:"version"`
	Action    string `json:"action"`
	Timestamp string `json:"timestamp"`
}

func NewMenuSyncWebSocketHub(dbClient *config.AstraDBClient) *MenuSyncWebSocketHub {
	return &MenuSyncWebSocketHub{
		dbClient: dbClient,
		clients:  make(map[*websocket.Conn]bool),
	}
}

func (h *MenuSyncWebSocketHub) Start() {
	h.startOnce.Do(func() {
		if version, err := h.fetchMenuSyncVersion(); err == nil {
			h.lastVersion = version
		} else {
			fmt.Printf("[MenuSyncWS] Failed to fetch initial sync version: %v\n", err)
		}

		go func() {
			if _, err := h.dbClient.RefreshPaginatedRows(menuRowsPath, menuRowsPageSize, menuCacheTTL); err != nil {
				fmt.Printf("[MenuSyncWS] Failed to warm menu cache at startup: %v\n", err)
			}
		}()

		go h.watchMenuSync()
	})
}

func (h *MenuSyncWebSocketHub) HandleConnection(c *websocket.Conn) {
	h.mu.Lock()
	h.clients[c] = true
	currentVersion := h.lastVersion
	h.mu.Unlock()

	fmt.Printf("[MenuSyncWS] Client connected. Active clients: %d\n", h.clientCount())

	_ = c.WriteJSON(menuSyncWebSocketEvent{
		Type:      "menu_sync_connected",
		Version:   currentVersion,
		Action:    "connected",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	})

	defer func() {
		h.mu.Lock()
		delete(h.clients, c)
		h.mu.Unlock()
		_ = c.Close()
		fmt.Printf("[MenuSyncWS] Client disconnected. Active clients: %d\n", h.clientCount())
	}()

	for {
		if _, _, err := c.ReadMessage(); err != nil {
			return
		}
	}
}

func (h *MenuSyncWebSocketHub) watchMenuSync() {
	ticker := time.NewTicker(menuSyncWebSocketPollInterval)
	defer ticker.Stop()

	for range ticker.C {
		version, err := h.fetchMenuSyncVersion()
		if err != nil {
			fmt.Printf("[MenuSyncWS] Failed to fetch sync version: %v\n", err)
			continue
		}
		if version == 0 {
			continue
		}

		h.mu.Lock()
		if version == h.lastVersion {
			h.mu.Unlock()
			continue
		}

		h.lastVersion = version
		clients := make([]*websocket.Conn, 0, len(h.clients))
		for client := range h.clients {
			clients = append(clients, client)
		}
		h.mu.Unlock()

		h.dbClient.InvalidateCache(menuRowsPath)
		if _, err := h.dbClient.RefreshPaginatedRows(menuRowsPath, menuRowsPageSize, menuCacheTTL); err != nil {
			fmt.Printf("[MenuSyncWS] Failed to warm menu cache at version %d: %v\n", version, err)
		}

		event := menuSyncWebSocketEvent{
			Type:      "menu_sync_changed",
			Version:   version,
			Action:    "refresh_menu",
			Timestamp: time.Now().UTC().Format(time.RFC3339),
		}

		fmt.Printf("[MenuSyncWS] Broadcasting menu sync version %d to %d client(s)\n", version, len(clients))
		h.broadcast(event, clients)
	}
}

func (h *MenuSyncWebSocketHub) broadcast(event menuSyncWebSocketEvent, clients []*websocket.Conn) {
	for _, client := range clients {
		if err := client.WriteJSON(event); err != nil {
			h.mu.Lock()
			delete(h.clients, client)
			h.mu.Unlock()
			_ = client.Close()
		}
	}
}

func (h *MenuSyncWebSocketHub) fetchMenuSyncVersion() (int64, error) {
	respData, err := h.dbClient.FindDocumentsQuiet(
		"menu_sync",
		map[string]interface{}{"id": "menu_sync"},
		map[string]interface{}{"limit": 1},
	)
	if err != nil {
		return 0, err
	}

	var raw interface{}
	if err := json.Unmarshal(respData, &raw); err != nil {
		return 0, err
	}

	return extractMenuSyncVersion(raw), nil
}

func (h *MenuSyncWebSocketHub) clientCount() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.clients)
}
