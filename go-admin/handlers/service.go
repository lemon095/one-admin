package handlers

import (
	"errors"

	"go-admin/models"
)

// UserService 用户服务接口
type UserService interface {
	GetAll() ([]models.User, error)
	GetByID(id int) (*models.User, error)
	Create(req models.CreateUserRequest) (*models.User, error)
	Update(id int, req models.UpdateUserRequest) (*models.User, error)
	Delete(id int) error
	Authenticate(username, password string) (*models.User, error)
	UpdateProfile(id int, req models.UpdateProfileRequest) (*models.User, error)
}

// MockUserService 模拟用户服务实现
type MockUserService struct {
	users []models.User
}

// NewMockUserService 创建模拟用户服务
func NewMockUserService() *MockUserService {
	return &MockUserService{
		users: []models.User{
			{ID: 1, Username: "admin", Password: "admin123", Email: "admin@example.com", Status: "active"},
			{ID: 2, Username: "user", Password: "user123", Email: "user@example.com", Status: "active"},
		},
	}
}

// GetAll 获取所有用户
func (s *MockUserService) GetAll() ([]models.User, error) {
	return s.users, nil
}

// GetByID 根据ID获取用户
func (s *MockUserService) GetByID(id int) (*models.User, error) {
	for _, user := range s.users {
		if user.ID == id {
			return &user, nil
		}
	}
	return nil, errors.New("user not found")
}

// Create 创建用户
func (s *MockUserService) Create(req models.CreateUserRequest) (*models.User, error) {
	newUser := models.User{
		ID:       len(s.users) + 1,
		Username: req.Username,
		Password: req.Password,
		Email:    req.Email,
		Status:   req.Status,
	}
	s.users = append(s.users, newUser)
	return &newUser, nil
}

// Update 更新用户
func (s *MockUserService) Update(id int, req models.UpdateUserRequest) (*models.User, error) {
	for i, user := range s.users {
		if user.ID == id {
			s.users[i].Username = req.Username
			s.users[i].Email = req.Email
			s.users[i].Status = req.Status
			return &s.users[i], nil
		}
	}
	return nil, errors.New("user not found")
}

// Delete 删除用户
func (s *MockUserService) Delete(id int) error {
	for i, user := range s.users {
		if user.ID == id {
			s.users = append(s.users[:i], s.users[i+1:]...)
			return nil
		}
	}
	return errors.New("user not found")
}

// Authenticate 用户认证
func (s *MockUserService) Authenticate(username, password string) (*models.User, error) {
	for _, user := range s.users {
		if user.Username == username && user.Password == password {
			return &user, nil
		}
	}
	return nil, errors.New("invalid credentials")
}
 