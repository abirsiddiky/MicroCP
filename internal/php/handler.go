package php

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/php", ListPHPVersions)
	r.POST("/php/:domain/switch", SwitchPHPVersion)
}

func ListPHPVersions(c *gin.Context) {
	c.String(http.StatusOK, "PHP Manager")
}

func SwitchPHPVersion(c *gin.Context) {
	c.String(http.StatusOK, "Switched")
}
