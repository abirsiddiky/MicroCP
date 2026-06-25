package websites

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/microcp/microcp/internal/db"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/websites", ListWebsites)
	r.GET("/websites/create", CreateWizardGET)
	r.POST("/websites/create", CreateWebsitePOST)
	r.POST("/websites/:id/delete", DeleteWebsite)
	r.POST("/websites/:id/suspend", SuspendWebsite)
	r.POST("/websites/:id/enable", EnableWebsite)
	r.POST("/websites/:id/php", ChangePHPVersion)
}

func ListWebsites(c *gin.Context) {
	c.HTML(http.StatusOK, "websites.html", nil)
}

func CreateWizardGET(c *gin.Context) {
	c.HTML(http.StatusOK, "websites_create.html", nil)
}

func CreateWebsitePOST(c *gin.Context) {
	domain := c.PostForm("domain")
	phpVersion := c.PostForm("php_version")
	if phpVersion == "" {
		phpVersion = "8.2"
	}

	_, err := db.DB.Exec("INSERT INTO websites (domain, php_version, document_root) VALUES (?, ?, ?)", domain, phpVersion, "/var/www/"+domain+"/public_html")
	if err != nil {
		c.String(http.StatusInternalServerError, "Failed to insert into db: %v", err)
		return
	}

	c.Header("HX-Redirect", "/websites")
	c.Status(http.StatusOK)
}

func DeleteWebsite(c *gin.Context) {
	db.DB.Exec("DELETE FROM websites WHERE id = ?", c.Param("id"))
	c.Header("HX-Redirect", "/websites")
	c.Status(http.StatusOK)
}

func SuspendWebsite(c *gin.Context) {
	c.Status(http.StatusOK)
}

func EnableWebsite(c *gin.Context) {
	c.Status(http.StatusOK)
}

func ChangePHPVersion(c *gin.Context) {
	c.Status(http.StatusOK)
}
