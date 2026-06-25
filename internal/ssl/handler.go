package ssl

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/ssl", ListSSL)
	r.POST("/ssl/:domain/issue", IssueSSL)
	r.POST("/ssl/:domain/revoke", RevokeSSL)
}

func ListSSL(c *gin.Context) {
	c.HTML(http.StatusOK, "ssl.html", nil)
}

func IssueSSL(c *gin.Context) { c.Status(http.StatusOK) }
func RevokeSSL(c *gin.Context) { c.Status(http.StatusOK) }
