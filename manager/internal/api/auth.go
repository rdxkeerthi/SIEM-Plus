package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/siem-plus/manager/internal/config"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthHandler struct {
	db  *gorm.DB
	cfg *config.Config
}

func NewAuthHandler(db *gorm.DB, cfg *config.Config) *AuthHandler {
	return &AuthHandler{db: db, cfg: cfg}
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type RegisterRequest struct {
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=8"`
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
	TenantID  string `json:"tenant_id"`
}

type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Query user from database
	var user struct {
		ID           string
		Email        string
		PasswordHash string
		TenantID     string
		Role         string
	}

	err := h.db.Raw(`
		SELECT id, email, password_hash, tenant_id, role 
		FROM users 
		WHERE email = ? AND status = 'active'
	`, req.Email).Scan(&user).Error

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Generate tokens
	accessToken, err := h.generateToken(user.ID, user.TenantID, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	// Update last login
	h.db.Exec("UPDATE users SET last_login = NOW() WHERE id = ?", user.ID)

	c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: accessToken, // TODO: Implement proper refresh token
		ExpiresIn:    h.cfg.JWT.Expiration,
	})
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Get or create tenant
	tenantID := req.TenantID
	if tenantID == "" {
		// Get default tenant
		var defaultTenant struct {
			ID string
		}
		h.db.Raw("SELECT id FROM tenants WHERE slug = 'default'").Scan(&defaultTenant)
		tenantID = defaultTenant.ID
	}

	// Create user
	userID := uuid.New().String()
	err = h.db.Exec(`
		INSERT INTO users (id, tenant_id, email, password_hash, first_name, last_name, role)
		VALUES (?, ?, ?, ?, ?, ?, 'user')
	`, userID, tenantID, req.Email, string(hashedPassword), req.FirstName, req.LastName).Error

	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "User already exists"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "User created successfully",
		"user_id": userID,
	})
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	// TODO: Implement refresh token logic
	c.JSON(http.StatusNotImplemented, gin.H{"error": "Not implemented"})
}

func (h *AuthHandler) generateToken(userID, tenantID, role string) (string, error) {
	claims := jwt.MapClaims{
		"user_id":   userID,
		"tenant_id": tenantID,
		"role":      role,
		"exp":       time.Now().Add(time.Duration(h.cfg.JWT.Expiration) * time.Second).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(h.cfg.JWT.Secret))
}
