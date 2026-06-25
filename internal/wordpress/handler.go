package wordpress

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/wordpress", ListWordPress)
	r.POST("/wordpress/install", InstallWordPress)
	r.POST("/wordpress/:domain/update-core", UpdateCore)
	r.POST("/wordpress/:domain/update-plugins", UpdatePlugins)
	r.POST("/wordpress/:domain/update-themes", UpdateThemes)
}

func ListWordPress(c *gin.Context) {
	c.HTML(http.StatusOK, "wordpress.html", nil)
}

func InstallWordPress(c *gin.Context) {
	c.String(http.StatusOK, "Install started")
}

func UpdateCore(c *gin.Context) { c.String(http.StatusOK, "OK") }
func UpdatePlugins(c *gin.Context) { c.String(http.StatusOK, "OK") }
func UpdateThemes(c *gin.Context) { c.String(http.StatusOK, "OK") }
