package monitoring

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/microcp/microcp/internal/db"
	"github.com/microcp/microcp/internal/websocket"
	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/mem"
)

func Dashboard(c *gin.Context) {
	var websitesCount int
	db.DB.QueryRow("SELECT COUNT(*) FROM websites").Scan(&websitesCount)

	var databasesCount int
	db.DB.QueryRow("SELECT COUNT(*) FROM databases").Scan(&databasesCount)

	c.HTML(http.StatusOK, "dashboard.html", gin.H{
		"WebsitesCount":  websitesCount,
		"DatabasesCount": databasesCount,
	})
}

func StartBroadcast(hub *websocket.Hub) {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()
	for {
		<-ticker.C

		cpuPercent, _ := cpu.Percent(0, false)
		vMem, _ := mem.VirtualMemory()

		var cpuVal float64
		if len(cpuPercent) > 0 {
			cpuVal = cpuPercent[0]
		}

		stats := map[string]interface{}{
			"cpu":         cpuVal,
			"ram_used":    vMem.Used,
			"ram_total":   vMem.Total,
			"ram_percent": vMem.UsedPercent,
		}

		hub.Broadcast <- stats
	}
}
