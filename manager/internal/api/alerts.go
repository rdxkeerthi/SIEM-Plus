package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AlertHandler struct {
	db *gorm.DB
}

func NewAlertHandler(db *gorm.DB) *AlertHandler {
	return &AlertHandler{db: db}
}

func (h *AlertHandler) List(c *gin.Context) {
	tenantID := c.GetString("tenant_id")
	status := c.DefaultQuery("status", "")
	severity := c.DefaultQuery("severity", "")

	query := `
		SELECT a.*, r.name as rule_name, ag.hostname
		FROM alerts a
		LEFT JOIN detection_rules r ON a.rule_id = r.id
		LEFT JOIN agents ag ON a.agent_id = ag.id
		WHERE a.tenant_id = ?
	`
	args := []interface{}{tenantID}

	if status != "" {
		query += " AND a.status = ?"
		args = append(args, status)
	}

	if severity != "" {
		query += " AND a.severity = ?"
		args = append(args, severity)
	}

	query += " ORDER BY a.created_at DESC LIMIT 100"

	var alerts []map[string]interface{}
	h.db.Raw(query, args...).Scan(&alerts)

	c.JSON(http.StatusOK, gin.H{"alerts": alerts})
}

func (h *AlertHandler) Get(c *gin.Context) {
	alertID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var alert map[string]interface{}
	err := h.db.Raw(`
		SELECT a.*, r.name as rule_name, r.description as rule_description,
		       ag.hostname, ag.ip_address
		FROM alerts a
		LEFT JOIN detection_rules r ON a.rule_id = r.id
		LEFT JOIN agents ag ON a.agent_id = ag.id
		WHERE a.id = ? AND a.tenant_id = ?
	`, alertID, tenantID).Scan(&alert).Error

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alert not found"})
		return
	}

	c.JSON(http.StatusOK, alert)
}

func (h *AlertHandler) Update(c *gin.Context) {
	alertID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var req struct {
		Status string `json:"status"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result := h.db.Exec(`
		UPDATE alerts 
		SET status = ?, updated_at = NOW()
		WHERE id = ? AND tenant_id = ?
	`, req.Status, alertID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alert not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert updated"})
}

func (h *AlertHandler) Assign(c *gin.Context) {
	alertID := c.Param("id")
	tenantID := c.GetString("tenant_id")
	userID := c.GetString("user_id")

	var req struct {
		AssignedTo string `json:"assigned_to"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	assignTo := req.AssignedTo
	if assignTo == "" {
		assignTo = userID
	}

	result := h.db.Exec(`
		UPDATE alerts 
		SET assigned_to = ?, updated_at = NOW()
		WHERE id = ? AND tenant_id = ?
	`, assignTo, alertID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alert not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert assigned"})
}

func (h *AlertHandler) Resolve(c *gin.Context) {
	alertID := c.Param("id")
	tenantID := c.GetString("tenant_id")
	userID := c.GetString("user_id")

	result := h.db.Exec(`
		UPDATE alerts 
		SET status = 'resolved', 
		    resolved_at = NOW(),
		    resolved_by = ?,
		    updated_at = NOW()
		WHERE id = ? AND tenant_id = ?
	`, userID, alertID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alert not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert resolved"})
}
