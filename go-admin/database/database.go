package database

import (
	"fmt"
	"log"

	"go-admin/config"
	"go-admin/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// InitDatabase 初始化数据库连接
func InitDatabase(cfg *config.Config) error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.DBName,
	)

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	DB = db

	// 自动迁移数据库表
	if err := AutoMigrate(); err != nil {
		return fmt.Errorf("failed to migrate database: %v", err)
	}

	// 初始化默认用户
	if err := InitDefaultUsers(); err != nil {
		return fmt.Errorf("failed to init default users: %v", err)
	}

	log.Println("Database initialized successfully")
	return nil
}

// AutoMigrate 自动迁移数据库表
func AutoMigrate() error {
	return DB.AutoMigrate(
		&models.User{},
		&models.Image{},
	)
}

// InitDefaultUsers 初始化默认用户
func InitDefaultUsers() error {
	// 检查是否已有用户
	var count int64
	DB.Model(&models.User{}).Count(&count)
	if count > 0 {
		return nil // 已有用户，跳过初始化
	}

	// 创建默认用户
	defaultUsers := []models.User{
		{
			Username: "admin",
			Password: "admin123", // 实际项目中应该加密
			Email:    "admin@example.com",
			Status:   "active",
		},
		{
			Username: "user",
			Password: "user123", // 实际项目中应该加密
			Email:    "user@example.com",
			Status:   "active",
		},
	}

	for _, user := range defaultUsers {
		if err := DB.Create(&user).Error; err != nil {
			return fmt.Errorf("failed to create default user %s: %v", user.Username, err)
		}
	}

	log.Println("Default users created successfully")
	return nil
}
