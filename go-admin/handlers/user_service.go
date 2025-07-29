package handlers

import (
	"errors"

	"go-admin/database"
	"go-admin/models"
)

// UserServiceImpl 用户服务实现
type UserServiceImpl struct{}

// NewUserService 创建用户服务
func NewUserService() *UserServiceImpl {
	return &UserServiceImpl{}
}

// GetAll 获取所有用户
func (s *UserServiceImpl) GetAll() ([]models.User, error) {
	var users []models.User
	err := database.DB.Find(&users).Error
	return users, err
}

// GetByID 根据ID获取用户
func (s *UserServiceImpl) GetByID(id int) (*models.User, error) {
	var user models.User
	err := database.DB.First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// Create 创建用户
func (s *UserServiceImpl) Create(req models.CreateUserRequest) (*models.User, error) {
	// 检查用户名是否已存在
	var existingUser models.User
	if err := database.DB.Where("username = ?", req.Username).First(&existingUser).Error; err == nil {
		return nil, errors.New("username already exists")
	}

	// 检查邮箱是否已存在
	if err := database.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		return nil, errors.New("email already exists")
	}

	user := models.User{
		Username: req.Username,
		Password: req.Password, // 实际项目中应该加密
		Email:    req.Email,
		Status:   req.Status,
	}

	err := database.DB.Create(&user).Error
	if err != nil {
		return nil, err
	}

	return &user, nil
}

// Update 更新用户
func (s *UserServiceImpl) Update(id int, req models.UpdateUserRequest) (*models.User, error) {
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		return nil, errors.New("user not found")
	}

	// 检查用户名是否已被其他用户使用
	var existingUser models.User
	if err := database.DB.Where("username = ? AND id != ?", req.Username, id).First(&existingUser).Error; err == nil {
		return nil, errors.New("username already exists")
	}

	// 检查邮箱是否已被其他用户使用
	if err := database.DB.Where("email = ? AND id != ?", req.Email, id).First(&existingUser).Error; err == nil {
		return nil, errors.New("email already exists")
	}

	user.Username = req.Username
	user.Email = req.Email
	user.Status = req.Status

	err := database.DB.Save(&user).Error
	if err != nil {
		return nil, err
	}

	return &user, nil
}

// Delete 删除用户
func (s *UserServiceImpl) Delete(id int) error {
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		return errors.New("user not found")
	}

	return database.DB.Delete(&user).Error
}

// Authenticate 用户认证
func (s *UserServiceImpl) Authenticate(username, password string) (*models.User, error) {
	var user models.User
	err := database.DB.Where("username = ? AND password = ?", username, password).First(&user).Error
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	if user.Status != "active" {
		return nil, errors.New("user account is disabled")
	}

	return &user, nil
}

// UpdateProfile 更新用户个人信息
func (s *UserServiceImpl) UpdateProfile(id int, req models.UpdateProfileRequest) (*models.User, error) {
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		return nil, errors.New("user not found")
	}

	// 检查用户名是否已被其他用户使用
	if req.Username != "" && req.Username != user.Username {
		var existingUser models.User
		if err := database.DB.Where("username = ? AND id != ?", req.Username, id).First(&existingUser).Error; err == nil {
			return nil, errors.New("username already exists")
		}
		user.Username = req.Username
	}

	// 检查邮箱是否已被其他用户使用
	if req.Email != "" && req.Email != user.Email {
		var existingUser models.User
		if err := database.DB.Where("email = ? AND id != ?", req.Email, id).First(&existingUser).Error; err == nil {
			return nil, errors.New("email already exists")
		}
		user.Email = req.Email
	}

	// 更新密码
	if req.Password != "" {
		user.Password = req.Password // 实际项目中应该加密
	}

	err := database.DB.Save(&user).Error
	if err != nil {
		return nil, err
	}

	return &user, nil
}
