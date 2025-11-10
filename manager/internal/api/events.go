package api

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type EventHandler struct {
	db    *gorm.DB
	redis *redis.Client
}

func NewEventHandler(db *gorm.DB, redis *redis.Client) *EventHandler {
	return &EventHandler{db: db, redis: redis}
}

func (h *EventHandler) Ingest(c *gin.Context) {
	tenantID := c.GetString("tenant_id")

	var req struct {
		Events []map[string]interface{} `json:"events" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Send events to Kafka for processing
	// For now, just acknowledge receipt
	
	// Increment event counter in Redis
	ctx := context.Background()
	h.redis.IncrBy(ctx, "events:"+tenantID+":count", int64(len(req.Events)))

	c.JSON(http.StatusAccepted, gin.H{
		"message":       "Events queued for processing",
		"event_count":   len(req.Events),
		"tenant_id":     tenantID,
	})
}
