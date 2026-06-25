package database

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/microcp/microcp/internal/db"
)

func RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/databases", ListDatabases)
	r.POST("/databases/create", CreateDatabase)
	r.POST("/databases/:id/delete", DeleteDatabase)
	r.POST("/databases/user/create", CreateUser)
}

func ListDatabases(c *gin.Context) {
	c.HTML(http.StatusOK, "databases.html", nil)
}

func CreateDatabase(c *gin.Context) {
	name := c.PostForm("name")
	dbUser := c.PostForm("db_user")
	db.DB.Exec("INSERT INTO databases (name, db_user) VALUES (?, ?)", name, dbUser)
	c.Header("HX-Redirect", "/databases")
	c.Status(http.StatusOK)
}

func DeleteDatabase(c *gin.Context) {
	db.DB.Exec("DELETE FROM databases WHERE id = ?", c.Param("id"))
	c.Header("HX-Redirect", "/databases")
	c.Status(http.StatusOK)
}

func CreateUser(c *gin.Context) {
	c.Status(http.StatusOK)
}
