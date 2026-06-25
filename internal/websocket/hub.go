package websocket

import (
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type Hub struct {
	clients   map[*websocket.Conn]bool
	Broadcast chan interface{}
	mu        sync.Mutex
}

func NewHub() *Hub {
	return &Hub{
		clients:   make(map[*websocket.Conn]bool),
		Broadcast: make(chan interface{}),
	}
}

func (h *Hub) Run() {
	for {
		message := <-h.Broadcast

		h.mu.Lock()
		for client := range h.clients {
			err := client.WriteJSON(message)
			if err != nil {
				client.Close()
				delete(h.clients, client)
			}
		}
		h.mu.Unlock()
	}
}

func ServeWS(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}
	hub.mu.Lock()
	hub.clients[conn] = true
	hub.mu.Unlock()
}
