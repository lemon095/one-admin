package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"go-admin/config"
	"go-admin/database"
	"go-admin/models"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// ImageService 图片服务接口
type ImageService interface {
	UploadImage(file *multipart.FileHeader, expireValue int, expireUnit string) (*models.Image, error)
	GetImageByID(id int) (*models.Image, error)
	GetImageByCode(imageCode string) (*models.Image, error)
	GetAllImages(page, pageSize int) (*models.ImageListResponse, error)
	GetRandomImage() (*models.Image, error)
	DeleteImage(id int) error
	DeleteExpiredImages() error
	ScheduleDeleteTask(imageID int, imageCode, filePath string) error
	ScheduleExpireTask(imageID int, imageCode, filePath string) error
}

// ImageServiceImpl 图片服务实现
type ImageServiceImpl struct {
	uploadDir   string
	redisClient *redis.Client
}

// NewImageService 创建图片服务
func NewImageService(redisClient *redis.Client) *ImageServiceImpl {
	// 创建上传目录
	uploadDir := "./uploads/images"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		panic(fmt.Sprintf("Failed to create upload directory: %v", err))
	}

	return &ImageServiceImpl{
		uploadDir:   uploadDir,
		redisClient: redisClient,
	}
}

// UploadImage 上传图片
func (s *ImageServiceImpl) UploadImage(file *multipart.FileHeader, expireValue int, expireUnit string) (*models.Image, error) {
	// 验证文件类型
	if !s.isValidImageType(file.Filename) {
		return nil, errors.New("invalid image type, only support jpg, jpeg, png, gif")
	}

	// 验证文件大小 (最大 10MB)
	if file.Size > 10*1024*1024 {
		return nil, errors.New("file size too large, maximum 10MB")
	}

	// 生成唯一图片码
	imageCode := s.generateImageCode()

	// 生成文件名
	ext := filepath.Ext(file.Filename)
	fileName := imageCode + ext
	filePath := filepath.Join(s.uploadDir, fileName)

	// 保存文件
	src, err := file.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %v", err)
	}
	defer src.Close()

	dst, err := os.Create(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to create file: %v", err)
	}
	defer dst.Close()

	if _, err = io.Copy(dst, src); err != nil {
		return nil, fmt.Errorf("failed to save file: %v", err)
	}

	// 计算过期时间
	var expireTime time.Time
	switch expireUnit {
	case "minutes":
		expireTime = time.Now().Add(time.Duration(expireValue) * time.Minute)
	case "hours":
		expireTime = time.Now().Add(time.Duration(expireValue) * time.Hour)
	case "days":
		expireTime = time.Now().AddDate(0, 0, expireValue)
	default:
		return nil, errors.New("invalid time unit")
	}

	// 创建图片记录
	image := &models.Image{
		ImageCode:  imageCode,
		FileName:   file.Filename,
		FilePath:   filePath,
		FileSize:   file.Size,
		FileType:   strings.ToLower(ext[1:]), // 去掉点号
		ExpireTime: expireTime,
		Status:     "active",
	}

	if err := database.DB.Create(image).Error; err != nil {
		// 删除已保存的文件
		os.Remove(filePath)
		return nil, fmt.Errorf("failed to save image record: %v", err)
	}

	return image, nil
}

// GetImageByID 根据ID获取图片
func (s *ImageServiceImpl) GetImageByID(id int) (*models.Image, error) {
	var image models.Image
	if err := database.DB.First(&image, id).Error; err != nil {
		return nil, errors.New("image not found")
	}
	return &image, nil
}

// GetImageByCode 根据图片码获取图片
func (s *ImageServiceImpl) GetImageByCode(imageCode string) (*models.Image, error) {
	var image models.Image
	if err := database.DB.Where("image_code = ?", imageCode).First(&image).Error; err != nil {
		return nil, errors.New("image not found")
	}
	return &image, nil
}

// GetAllImages 获取所有图片（分页）
func (s *ImageServiceImpl) GetAllImages(page, pageSize int) (*models.ImageListResponse, error) {
	var images []models.Image
	var total int64

	// 获取总数
	if err := database.DB.Model(&models.Image{}).Count(&total).Error; err != nil {
		return nil, err
	}

	// 分页查询
	offset := (page - 1) * pageSize
	if err := database.DB.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&images).Error; err != nil {
		return nil, err
	}

	// 转换为响应格式
	items := make([]models.ImageResponse, len(images))
	for i, image := range images {
		items[i] = image.ToResponse()
	}

	return &models.ImageListResponse{
		Total: int(total),
		Items: items,
	}, nil
}

// GetRandomImage 随机获取一个有效的图片
func (s *ImageServiceImpl) GetRandomImage() (*models.Image, error) {
	var image models.Image

	// 查询有效的图片（未过期且状态为active）
	err := database.DB.Where("status = ? AND expire_time > ?", "active", time.Now()).
		Order("RAND()").
		First(&image).Error

	if err != nil {
		return nil, errors.New("没有可用的图片")
	}

	return &image, nil
}

// DeleteImage 删除图片
func (s *ImageServiceImpl) DeleteImage(id int) error {
	var image models.Image
	if err := database.DB.First(&image, id).Error; err != nil {
		return errors.New("image not found")
	}

	// 使用Redis异步删除
	return s.ScheduleDeleteTask(image.ID, image.ImageCode, image.FilePath)
}

// DeleteExpiredImages 删除过期图片
func (s *ImageServiceImpl) DeleteExpiredImages() error {
	var expiredImages []models.Image
	now := time.Now()

	// 查找过期图片
	if err := database.DB.Where("expire_time < ? AND status = ?", now, "active").Find(&expiredImages).Error; err != nil {
		return err
	}

	// 删除过期图片
	for _, image := range expiredImages {
		// 删除文件
		if err := os.Remove(image.FilePath); err != nil && !os.IsNotExist(err) {
			continue // 继续删除其他图片
		}

		// 更新状态为过期
		database.DB.Model(&image).Update("status", "expired")
	}

	return nil
}

// StartCleanupScheduler 启动清理调度器
func (s *ImageServiceImpl) StartCleanupScheduler() {
	// 每小时检查一次过期图片
	ticker := time.NewTicker(1 * time.Hour)
	go func() {
		for {
			select {
			case <-ticker.C:
				if err := s.DeleteExpiredImages(); err != nil {
					log.Printf("Failed to cleanup expired images: %v", err)
				} else {
					log.Println("Expired images cleanup completed")
				}
			}
		}
	}()
	log.Println("Image cleanup scheduler started")
}

// isValidImageType 验证图片类型
func (s *ImageServiceImpl) isValidImageType(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	validTypes := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
	}
	return validTypes[ext]
}

// generateImageCode 生成唯一图片码
func (s *ImageServiceImpl) generateImageCode() string {
	// 使用UUID生成唯一码，取前8位
	return strings.ReplaceAll(uuid.New().String()[:8], "-", "")
}

// ScheduleDeleteTask 调度删除任务
func (s *ImageServiceImpl) ScheduleDeleteTask(imageID int, imageCode, filePath string) error {
	task := models.NewDeleteTask("delete", imageID, imageCode, filePath)
	taskJSON, err := json.Marshal(task)
	if err != nil {
		return fmt.Errorf("failed to marshal delete task: %v", err)
	}

	ctx := context.Background()
	return s.redisClient.RPush(ctx, config.ImageDeleteQueue, taskJSON).Err()
}

// ScheduleExpireTask 调度过期任务
func (s *ImageServiceImpl) ScheduleExpireTask(imageID int, imageCode, filePath string) error {
	task := models.NewDeleteTask("expire", imageID, imageCode, filePath)
	taskJSON, err := json.Marshal(task)
	if err != nil {
		return fmt.Errorf("failed to marshal expire task: %v", err)
	}

	return s.redisClient.RPush(context.Background(), config.ImageExpireQueue, taskJSON).Err()
}
