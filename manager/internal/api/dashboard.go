package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type DashboardHandler struct {
	db *gorm.DB
}

func NewDashboardHandler(db *gorm.DB) *DashboardHandler {
	return &DashboardHandler{db: db}
}

func (h *DashboardHandler) GetStats(c *gin.Context) {
	tenantID := c.GetString("tenant_id")

	var stats struct {
		TotalAgents      int64
		ActiveAgents     int64
		TotalAlerts      int64
		OpenAlerts       int64
		CriticalAlerts   int64
		TotalCases       int64
		OpenCases        int64
		TotalRules       int64
		EnabledRules     int64
	}

	// Get agent stats
	h.db.Raw("SELECT COUNT(*) FROM agents WHERE tenant_id = ?", tenantID).Scan(&stats.TotalAgents)
	h.db.Raw("SELECT COUNT(*) FROM agents WHERE tenant_id = ? AND status = 'active'", tenantID).Scan(&stats.ActiveAgents)

	// Get alert stats
	h.db.Raw("SELECT COUNT(*) FROM alerts WHERE tenant_id = ?", tenantID).Scan(&stats.TotalAlerts)
	h.db.Raw("SELECT COUNT(*) FROM alerts WHERE tenant_id = ? AND status = 'open'", tenantID).Scan(&stats.OpenAlerts)
	h.db.Raw("SELECT COUNT(*) FROM alerts WHERE tenant_id = ? AND severity = 'critical' AND status = 'open'", tenantID).Scan(&stats.CriticalAlerts)

	// Get case stats
	h.db.Raw("SELECT COUNT(*) FROM cases WHERE tenant_id = ?", tenantID).Scan(&stats.TotalCases)
	h.db.Raw("SELECT COUNT(*) FROM cases WHERE tenant_id = ? AND status = 'open'", tenantID).Scan(&stats.OpenCases)

	// Get rule stats
	h.db.Raw("SELECT COUNT(*) FROM detection_rules WHERE tenant_id = ?", tenantID).Scan(&stats.TotalRules)
	h.db.Raw("SELECT COUNT(*) FROM detection_rules WHERE tenant_id = ? AND enabled = true", tenantID).Scan(&stats.EnabledRules)

	c.JSON(http.StatusOK, stats)
}

func (h *DashboardHandler) GetTimeline(c *gin.Context) {
	tenantID := c.GetString("tenant_id")
	days := c.DefaultQuery("days", "7")

	var timeline []map[string]interface{}
	h.db.Raw(`
		SELECT 
		    DATE(created_at) as date,
		    COUNT(*) as count,
		    severity
		FROM alerts
		WHERE tenant_id = ? 
		  AND created_at >= NOW() - INTERVAL '? days'
		GROUP BY DATE(created_at), severity
		ORDER BY date DESC
	`, tenantID, days).Scan(&timeline)

	c.JSON(http.StatusOK, gin.H{"timeline": timeline})
}
