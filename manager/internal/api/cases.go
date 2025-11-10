package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CaseHandler struct {
	db *gorm.DB
}

func NewCaseHandler(db *gorm.DB) *CaseHandler {
	return &CaseHandler{db: db}
}

func (h *CaseHandler) List(c *gin.Context) {
	tenantID := c.GetString("tenant_id")

	var cases []map[string]interface{}
	h.db.Raw(`
		SELECT c.*, 
		       u.email as assigned_to_email,
		       COUNT(ca.alert_id) as alert_count
		FROM cases c
		LEFT JOIN users u ON c.assigned_to = u.id
		LEFT JOIN case_alerts ca ON c.id = ca.case_id
		WHERE c.tenant_id = ?
		GROUP BY c.id, u.email
		ORDER BY c.created_at DESC
	`, tenantID).Scan(&cases)

	c.JSON(http.StatusOK, gin.H{"cases": cases})
}

func (h *CaseHandler) Get(c *gin.Context) {
	caseID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var caseData map[string]interface{}
	err := h.db.Raw(`
		SELECT c.*, 
		       u.email as assigned_to_email,
		       creator.email as created_by_email
		FROM cases c
		LEFT JOIN users u ON c.assigned_to = u.id
		LEFT JOIN users creator ON c.created_by = creator.id
		WHERE c.id = ? AND c.tenant_id = ?
	`, caseID, tenantID).Scan(&caseData).Error

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Case not found"})
		return
	}

	// Get associated alerts
	var alerts []map[string]interface{}
	h.db.Raw(`
		SELECT a.*
		FROM alerts a
		JOIN case_alerts ca ON a.id = ca.alert_id
		WHERE ca.case_id = ?
	`, caseID).Scan(&alerts)

	caseData["alerts"] = alerts

	c.JSON(http.StatusOK, caseData)
}

func (h *CaseHandler) Create(c *gin.Context) {
	var req struct {
		Title       string `json:"title" binding:"required"`
		Description string `json:"description"`
		Severity    string `json:"severity" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tenantID := c.GetString("tenant_id")
	userID := c.GetString("user_id")
	caseID := uuid.New().String()

	err := h.db.Exec(`
		INSERT INTO cases (id, tenant_id, title, description, severity, created_by)
		VALUES (?, ?, ?, ?, ?, ?)
	`, caseID, tenantID, req.Title, req.Description, req.Severity, userID).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create case"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"case_id": caseID,
		"message": "Case created successfully",
	})
}

func (h *CaseHandler) Update(c *gin.Context) {
	caseID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result := h.db.Exec(`
		UPDATE cases 
		SET title = COALESCE(?, title),
		    description = COALESCE(?, description),
		    status = COALESCE(?, status),
		    severity = COALESCE(?, severity),
		    assigned_to = COALESCE(?, assigned_to),
		    updated_at = NOW()
		WHERE id = ? AND tenant_id = ?
	`, req["title"], req["description"], req["status"], req["severity"], 
	   req["assigned_to"], caseID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Case not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Case updated"})
}

func (h *CaseHandler) Delete(c *gin.Context) {
	caseID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	result := h.db.Exec("DELETE FROM cases WHERE id = ? AND tenant_id = ?", caseID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Case not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Case deleted"})
}

func (h *CaseHandler) AddAlert(c *gin.Context) {
	caseID := c.Param("id")
	
	var req struct {
		AlertID string `json:"alert_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.db.Exec(`
		INSERT INTO case_alerts (case_id, alert_id)
		VALUES (?, ?)
		ON CONFLICT DO NOTHING
	`, caseID, req.AlertID).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add alert to case"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert added to case"})
}
