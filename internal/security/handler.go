package security

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/security", SecurityDashboard)
}

func SecurityDashboard(c *gin.Context) {
	c.HTML(http.StatusOK, "security.html", nil)
}
