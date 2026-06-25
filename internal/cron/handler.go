package cron

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/cron", ListCronJobs)
	r.POST("/cron/create", CreateCronJob)
}

func ListCronJobs(c *gin.Context) {
	c.HTML(http.StatusOK, "cron.html", nil)
}

func CreateCronJob(c *gin.Context) { c.Status(http.StatusOK) }
