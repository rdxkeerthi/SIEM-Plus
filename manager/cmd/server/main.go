package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/segmentio/kafka-go"
	"github.com/siem-plus/manager/internal/api"
	"github.com/siem-plus/manager/internal/config"
	"github.com/siem-plus/manager/internal/database"
	"github.com/siem-plus/manager/internal/middleware"
	"go.uber.org/zap"
)

func main() {
	// Initialize logger
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		logger.Fatal("Failed to load configuration", zap.Error(err))
	}

	// Initialize database
	db, err := database.NewPostgresDB(cfg.Database.URL)
	if err != nil {
		logger.Fatal("Failed to connect to database", zap.Error(err))
	}

	// Initialize Redis
	redisClient := database.NewRedisClient(cfg.Redis.URL)

	// Setup Kafka writer
	kafkaWriter := kafka.NewWriter(kafka.WriterConfig{
		Brokers:  cfg.Kafka.Brokers,
		Topic:    cfg.Kafka.Topic,
		Balancer: &kafka.Hash{},
	})
	defer kafkaWriter.Close()

	// Setup Gin router
	if cfg.Server.Mode == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.Logger(logger))
	router.Use(middleware.CORS())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"version": "0.1.0",
		})
	})

	// API routes
	v1 := router.Group("/api/v1")
	{
		// Public routes
		auth := v1.Group("/auth")
		{
			authHandler := api.NewAuthHandler(db, cfg)
			auth.POST("/login", authHandler.Login)
			auth.POST("/register", authHandler.Register)
			auth.POST("/refresh", authHandler.RefreshToken)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(middleware.AuthRequired(cfg.JWT.Secret))
		{
			// Agents
			agents := protected.Group("/agents")
			{
				agentHandler := api.NewAgentHandler(db)
				agents.GET("", agentHandler.List)
				agents.GET("/:id", agentHandler.Get)
				agents.POST("", agentHandler.Create)
				agents.PUT("/:id", agentHandler.Update)
				agents.DELETE("/:id", agentHandler.Delete)
				agents.POST("/:id/commands", agentHandler.SendCommand)
			}

			// Alerts
			alerts := protected.Group("/alerts")
			{
				alertHandler := api.NewAlertHandler(db)
				alerts.GET("", alertHandler.List)
				alerts.GET("/:id", alertHandler.Get)
				alerts.PUT("/:id", alertHandler.Update)
				alerts.POST("/:id/assign", alertHandler.Assign)
				alerts.POST("/:id/resolve", alertHandler.Resolve)
			}

			// Detection Rules
			rules := protected.Group("/rules")
			{
				ruleHandler := api.NewRuleHandler(db)
				rules.GET("", ruleHandler.List)
				rules.GET("/:id", ruleHandler.Get)
				rules.POST("", ruleHandler.Create)
				rules.PUT("/:id", ruleHandler.Update)
				rules.DELETE("/:id", ruleHandler.Delete)
				rules.POST("/:id/test", ruleHandler.Test)
			}

			// Cases
			cases := protected.Group("/cases")
			{
				caseHandler := api.NewCaseHandler(db)
				cases.GET("", caseHandler.List)
				cases.GET("/:id", caseHandler.Get)
				cases.POST("", caseHandler.Create)
				cases.PUT("/:id", caseHandler.Update)
				cases.DELETE("/:id", caseHandler.Delete)
				cases.POST("/:id/alerts", caseHandler.AddAlert)
			}

			// Events (ingestion endpoint)
			events := protected.Group("/events")
			{
				eventHandler := api.NewEventHandler(db, redisClient, kafkaWriter)
				events.POST("", eventHandler.Ingest)
			}

			// Dashboard
			dashboard := protected.Group("/dashboard")
			{
				dashHandler := api.NewDashboardHandler(db)
				dashboard.GET("/stats", dashHandler.GetStats)
				dashboard.GET("/timeline", dashHandler.GetTimeline)
			}
		}
	}

	// Start server
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%d", cfg.Server.Port),
		Handler: router,
	}

	// Graceful shutdown
	go func() {
		logger.Info("Starting server", zap.Int("port", cfg.Server.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Server failed to start", zap.Error(err))
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", zap.Error(err))
	}

	logger.Info("Server exited")
}
