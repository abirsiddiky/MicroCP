package logs_handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/logs", ViewLogs)
}

func ViewLogs(c *gin.Context) {
	c.HTML(http.StatusOK, "logs.html", nil)
}
