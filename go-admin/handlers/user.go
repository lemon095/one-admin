package handlers

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"go-admin/models"
	"go-admin/utils"
)

// UserHandler 用户处理器
type UserHandler struct {
	userService UserService
}

// NewUserHandler 创建用户处理器
func NewUserHandler(userService UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
	}
}

// GetUsers 获取用户列表
func (h *UserHandler) GetUsers(c *gin.Context) {
	users, err := h.userService.GetAll()
	if err != nil {
		utils.InternalServerError(c, "Failed to get users")
		return
	}

	// 转换为响应格式
	var responses []models.UserResponse
	for _, user := range users {
		responses = append(responses, user.ToResponse())
	}

	utils.SuccessWithMessage(c, "Users retrieved successfully", responses)
}

// GetUser 获取单个用户
func (h *UserHandler) GetUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "Invalid user ID")
		return
	}

	user, err := h.userService.GetByID(id)
	if err != nil {
		utils.NotFound(c, "User not found")
		return
	}

	utils.SuccessWithMessage(c, "User retrieved successfully", user.ToResponse())
}

// CreateUser 创建用户
func (h *UserHandler) CreateUser(c *gin.Context) {
	var req models.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Invalid request body")
		return
	}

	user, err := h.userService.Create(req)
	if err != nil {
		utils.InternalServerError(c, "Failed to create user")
		return
	}

	utils.SuccessWithMessage(c, "User created successfully", user.ToResponse())
}

// UpdateUser 更新用户
func (h *UserHandler) UpdateUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "Invalid user ID")
		return
	}

	var req models.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Invalid request body")
		return
	}

	user, err := h.userService.Update(id, req)
	if err != nil {
		utils.InternalServerError(c, "Failed to update user")
		return
	}

	utils.SuccessWithMessage(c, "User updated successfully", user.ToResponse())
}

// DeleteUser 删除用户
func (h *UserHandler) DeleteUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "Invalid user ID")
		return
	}

	err = h.userService.Delete(id)
	if err != nil {
		utils.InternalServerError(c, "Failed to delete user")
		return
	}

	utils.SuccessWithMessage(c, "User deleted successfully", nil)
}

// UpdateProfile 更新个人信息
func (h *UserHandler) UpdateProfile(c *gin.Context) {
	userID := c.GetInt("user_id")

	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "Invalid request body")
		return
	}

	user, err := h.userService.UpdateProfile(userID, req)
	if err != nil {
		utils.InternalServerError(c, "Failed to update profile")
		return
	}

	utils.SuccessWithMessage(c, "Profile updated successfully", user.ToResponse())
}
 