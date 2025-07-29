package handlers

import (
	"github.com/gin-gonic/gin"
	"go-admin/models"
	"go-admin/utils"
)

// AuthHandler 认证处理器
type AuthHandler struct {
	jwtManager  *utils.JWTManager
	userService UserService
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler(jwtManager *utils.JWTManager, userService UserService) *AuthHandler {
	return &AuthHandler{
		jwtManager:  jwtManager,
		userService: userService,
	}
}

// Login 用户登录
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Invalid request body")
		return
	}

	// 验证用户名和密码
	user, err := h.userService.Authenticate(req.Username, req.Password)
	if err != nil {
		utils.Unauthorized(c, err.Error())
		return
	}

	// 生成JWT token
	token, err := h.jwtManager.GenerateToken(user.ID, user.Username)
	if err != nil {
		utils.InternalServerError(c, "Failed to generate token")
		return
	}

	// 返回登录响应
	response := models.LoginResponse{
		Token: token,
		User:  user.ToResponse(),
	}

	utils.SuccessWithMessage(c, "Login successful", response)
}

// GetProfile 获取当前用户信息
func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID := c.GetInt("user_id")

	user, err := h.userService.GetByID(userID)
	if err != nil {
		utils.NotFound(c, "User not found")
		return
	}

	utils.SuccessWithMessage(c, "Profile retrieved successfully", user.ToResponse())
}
 