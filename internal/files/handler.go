package files

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/files", FileBrowser)
	r.POST("/files/upload", UploadFile)
	r.POST("/files/delete", DeleteFile)
}

func FileBrowser(c *gin.Context) {
	c.HTML(http.StatusOK, "files.html", nil)
}

func UploadFile(c *gin.Context) {
	c.Status(http.StatusOK)
}

func DeleteFile(c *gin.Context) {
	c.Status(http.StatusOK)
}
