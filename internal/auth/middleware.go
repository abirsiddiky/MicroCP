package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		session, err := c.Cookie("microcp_session")
		if err != nil || session != "authenticated" {
			c.Redirect(http.StatusFound, "/login")
			c.Abort()
			return
		}
		c.Next()
	}
}
