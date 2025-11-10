package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RuleHandler struct {
	db *gorm.DB
}

func NewRuleHandler(db *gorm.DB) *RuleHandler {
	return &RuleHandler{db: db}
}

func (h *RuleHandler) List(c *gin.Context) {
	tenantID := c.GetString("tenant_id")

	var rules []map[string]interface{}
	h.db.Raw(`
		SELECT id, name, description, rule_type, severity, enabled, tags, created_at
		FROM detection_rules
		WHERE tenant_id = ?
		ORDER BY created_at DESC
	`, tenantID).Scan(&rules)

	c.JSON(http.StatusOK, gin.H{"rules": rules})
}

func (h *RuleHandler) Get(c *gin.Context) {
	ruleID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var rule map[string]interface{}
	err := h.db.Raw(`
		SELECT * FROM detection_rules
		WHERE id = ? AND tenant_id = ?
	`, ruleID, tenantID).Scan(&rule).Error

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
		return
	}

	c.JSON(http.StatusOK, rule)
}

func (h *RuleHandler) Create(c *gin.Context) {
	var req struct {
		Name        string   `json:"name" binding:"required"`
		Description string   `json:"description"`
		RuleType    string   `json:"rule_type" binding:"required"`
		Severity    string   `json:"severity" binding:"required"`
		RuleContent string   `json:"rule_content" binding:"required"`
		Tags        []string `json:"tags"`
		Enabled     bool     `json:"enabled"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tenantID := c.GetString("tenant_id")
	userID := c.GetString("user_id")
	ruleID := uuid.New().String()

	err := h.db.Exec(`
		INSERT INTO detection_rules 
		(id, tenant_id, name, description, rule_type, severity, rule_content, tags, enabled, created_by)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, ruleID, tenantID, req.Name, req.Description, req.RuleType, req.Severity, 
	   req.RuleContent, req.Tags, req.Enabled, userID).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create rule"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"rule_id": ruleID,
		"message": "Rule created successfully",
	})
}

func (h *RuleHandler) Update(c *gin.Context) {
	ruleID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result := h.db.Exec(`
		UPDATE detection_rules 
		SET name = COALESCE(?, name),
		    description = COALESCE(?, description),
		    severity = COALESCE(?, severity),
		    rule_content = COALESCE(?, rule_content),
		    enabled = COALESCE(?, enabled),
		    updated_at = NOW()
		WHERE id = ? AND tenant_id = ?
	`, req["name"], req["description"], req["severity"], req["rule_content"], 
	   req["enabled"], ruleID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Rule updated"})
}

func (h *RuleHandler) Delete(c *gin.Context) {
	ruleID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	result := h.db.Exec("DELETE FROM detection_rules WHERE id = ? AND tenant_id = ?", ruleID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Rule not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Rule deleted"})
}

func (h *RuleHandler) Test(c *gin.Context) {
	ruleID := c.Param("id")
	
	var req struct {
		TestEvents []map[string]interface{} `json:"test_events" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Test rule against sample events
	
	c.JSON(http.StatusOK, gin.H{
		"rule_id": ruleID,
		"matches": 0,
		"results": []interface{}{},
	})
}
