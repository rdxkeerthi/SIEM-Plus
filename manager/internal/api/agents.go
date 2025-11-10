package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AgentHandler struct {
	db *gorm.DB
}

func NewAgentHandler(db *gorm.DB) *AgentHandler {
	return &AgentHandler{db: db}
}

func (h *AgentHandler) List(c *gin.Context) {
	tenantID := c.GetString("tenant_id")
	
	var agents []map[string]interface{}
	h.db.Raw(`
		SELECT id, hostname, ip_address, os_type, os_version, 
		       agent_version, status, last_seen, created_at
		FROM agents
		WHERE tenant_id = ?
		ORDER BY created_at DESC
	`, tenantID).Scan(&agents)

	c.JSON(http.StatusOK, gin.H{"agents": agents})
}

func (h *AgentHandler) Get(c *gin.Context) {
	agentID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var agent map[string]interface{}
	err := h.db.Raw(`
		SELECT * FROM agents
		WHERE id = ? AND tenant_id = ?
	`, agentID, tenantID).Scan(&agent).Error

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Agent not found"})
		return
	}

	c.JSON(http.StatusOK, agent)
}

func (h *AgentHandler) Create(c *gin.Context) {
	var req struct {
		Hostname  string `json:"hostname" binding:"required"`
		IPAddress string `json:"ip_address"`
		OSType    string `json:"os_type"`
		OSVersion string `json:"os_version"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tenantID := c.GetString("tenant_id")
	agentID := uuid.New().String()
	registrationKey := uuid.New().String()

	err := h.db.Exec(`
		INSERT INTO agents (id, tenant_id, hostname, ip_address, os_type, os_version, registration_key, status)
		VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
	`, agentID, tenantID, req.Hostname, req.IPAddress, req.OSType, req.OSVersion, registrationKey).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create agent"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"agent_id":         agentID,
		"registration_key": registrationKey,
	})
}

func (h *AgentHandler) Update(c *gin.Context) {
	agentID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	var req map[string]interface{}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update agent
	result := h.db.Exec(`
		UPDATE agents 
		SET status = COALESCE(?, status),
		    metadata = COALESCE(?, metadata),
		    updated_at = NOW()
		WHERE id = ? AND tenant_id = ?
	`, req["status"], req["metadata"], agentID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Agent not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Agent updated"})
}

func (h *AgentHandler) Delete(c *gin.Context) {
	agentID := c.Param("id")
	tenantID := c.GetString("tenant_id")

	result := h.db.Exec("DELETE FROM agents WHERE id = ? AND tenant_id = ?", agentID, tenantID)

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Agent not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Agent deleted"})
}

func (h *AgentHandler) SendCommand(c *gin.Context) {
	agentID := c.Param("id")
	
	var req struct {
		Command string                 `json:"command" binding:"required"`
		Args    map[string]interface{} `json:"args"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Send command to agent via message queue
	
	c.JSON(http.StatusAccepted, gin.H{
		"message":   "Command queued",
		"agent_id":  agentID,
		"command":   req.Command,
	})
}
