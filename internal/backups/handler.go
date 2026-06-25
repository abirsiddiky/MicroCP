package backups

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/backups", ListBackups)
	r.POST("/backups/create", CreateBackup)
}

func ListBackups(c *gin.Context) {
	c.HTML(http.StatusOK, "backups.html", nil)
}

func CreateBackup(c *gin.Context) {
	c.Status(http.StatusOK)
}
