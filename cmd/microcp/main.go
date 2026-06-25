package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/microcp/microcp/internal/auth"
	"github.com/microcp/microcp/internal/backups"
	"github.com/microcp/microcp/internal/config"
	"github.com/microcp/microcp/internal/cron"
	"github.com/microcp/microcp/internal/database"
	"github.com/microcp/microcp/internal/db"
	"github.com/microcp/microcp/internal/files"
	"github.com/microcp/microcp/internal/logs_handler"
	"github.com/microcp/microcp/internal/monitoring"
	"github.com/microcp/microcp/internal/php"
	"github.com/microcp/microcp/internal/security"
	"github.com/microcp/microcp/internal/ssl"
	"github.com/microcp/microcp/internal/websocket"
	"github.com/microcp/microcp/internal/websites"
	"github.com/microcp/microcp/internal/wordpress"
)

func main() {
	cfg := config.Load()

	if err := db.Init(cfg.DBPath); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	auth.InitAdmin()

	r := gin.Default()
	r.Static("/static", "./web/static")
	r.LoadHTMLGlob("web/templates/*")

	hub := websocket.NewHub()
	go hub.Run()
	go monitoring.StartBroadcast(hub)

	r.GET("/login", auth.LoginGET)
	r.POST("/login", auth.LoginPOST)
	r.GET("/logout", auth.Logout)

	protected := r.Group("/")
	protected.Use(auth.Middleware())
	{
		protected.GET("/", monitoring.Dashboard)
		protected.GET("/ws", func(c *gin.Context) {
			websocket.ServeWS(hub, c.Writer, c.Request)
		})

		websites.RegisterRoutes(protected)
		php.RegisterRoutes(protected)
		wordpress.RegisterRoutes(protected)
		database.RegisterRoutes(protected)
		files.RegisterRoutes(protected)
		ssl.RegisterRoutes(protected)
		backups.RegisterRoutes(protected)
		cron.RegisterRoutes(protected)
		logs_handler.RegisterRoutes(protected)
		security.RegisterRoutes(protected)
	}

	port := cfg.Port
	if port == "" {
		port = "8080"
	}
	log.Printf("MicroCP running on port %s", port)
	r.Run("0.0.0.0:" + port)
}
