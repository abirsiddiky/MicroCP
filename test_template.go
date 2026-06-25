package main

import (
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.LoadHTMLGlob("web/templates/*")
	r.GET("/", func(c *gin.Context) {
		c.HTML(200, "dashboard.html", gin.H{})
	})
	log.Println("Starting...")
	r.Run(":8081")
}
