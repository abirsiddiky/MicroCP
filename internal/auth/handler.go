package auth

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/microcp/microcp/internal/db"
	"golang.org/x/crypto/bcrypt"
)

func InitAdmin() {
	var val string
	err := db.DB.QueryRow("SELECT value FROM settings WHERE key = 'admin_password'").Scan(&val)
	if err == sql.ErrNoRows {
		hash, _ := bcrypt.GenerateFromPassword([]byte("admin"), bcrypt.DefaultCost)
		db.DB.Exec("INSERT INTO settings (key, value) VALUES ('admin_password', ?)", string(hash))
	}
}

func LoginGET(c *gin.Context) {
	c.HTML(http.StatusOK, "login.html", nil)
}

func LoginPOST(c *gin.Context) {
	password := c.PostForm("password")

	var hash string
	err := db.DB.QueryRow("SELECT value FROM settings WHERE key = 'admin_password'").Scan(&hash)

	if err == nil && bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil {
		c.SetCookie("microcp_session", "authenticated", 3600*24, "/", "", false, true)
		c.Redirect(http.StatusFound, "/")
		return
	}

	c.HTML(http.StatusOK, "login.html", gin.H{"Error": "Invalid password"})
}

func Logout(c *gin.Context) {
	c.SetCookie("microcp_session", "", -1, "/", "", false, true)
	c.Redirect(http.StatusFound, "/login")
}
