package api

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/segmentio/kafka-go"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type EventHandler struct {
	db    *gorm.DB
	redis *redis.Client
	kafka *kafka.Writer
}

func NewEventHandler(db *gorm.DB, redis *redis.Client, kafkaWriter *kafka.Writer) *EventHandler {
	return &EventHandler{db: db, redis: redis, kafka: kafkaWriter}
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

	// Enrich and publish to Kafka
	ctx := context.Background()
	now := time.Now().UTC()
	msgs := make([]kafka.Message, 0, len(req.Events))
	for _, ev := range req.Events {
		ev["tenant_id"] = tenantID
		ev["ingested_at"] = now.Format(time.RFC3339)
		if _, ok := ev["source"]; !ok {
			ev["source"] = "agent"
		}
		payload, _ := json.Marshal(ev)
		msgs = append(msgs, kafka.Message{Key: []byte(tenantID), Value: payload})
	}

	if h.kafka != nil && len(msgs) > 0 {
		if err := h.kafka.WriteMessages(ctx, msgs...); err != nil {
			// do not fail the request; best-effort enqueue
		}
	}

	// Increment event counter in Redis
	h.redis.IncrBy(ctx, "events:"+tenantID+":count", int64(len(req.Events)))

	c.JSON(http.StatusAccepted, gin.H{
		"message":       "Events queued for processing",
		"event_count":   len(req.Events),
		"tenant_id":     tenantID,
	})
}
