package models

import (
	"time"
)

// Image 图片模型
type Image struct {
	ID         int       `json:"id" gorm:"primaryKey"`
	ImageCode  string    `json:"image_code" gorm:"uniqueIndex;size:50;not null"` // 唯一图片码
	FileName   string    `json:"file_name" gorm:"size:255;not null"`             // 原始文件名
	FilePath   string    `json:"file_path" gorm:"size:500;not null"`             // 存储路径
	FileSize   int64     `json:"file_size" gorm:"not null"`                      // 文件大小(字节)
	FileType   string    `json:"file_type" gorm:"size:50;not null"`              // 文件类型
	UploadTime time.Time `json:"upload_time" gorm:"autoCreateTime"`              // 上传时间
	ExpireTime time.Time `json:"expire_time" gorm:"not null"`                    // 过期时间
	Status     string    `json:"status" gorm:"size:20;default:'active'"`         // 状态: active, expired, deleted
	CreatedAt  time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt  time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

// ImageResponse 图片响应结构
func (i *Image) ToResponse() ImageResponse {
	now := time.Now()
	var remainingTime time.Duration
	var isExpired bool

	if i.ExpireTime.After(now) {
		remainingTime = i.ExpireTime.Sub(now)
		isExpired = false
	} else {
		remainingTime = 0
		isExpired = true
	}

	return ImageResponse{
		ID:            i.ID,
		ImageCode:     i.ImageCode,
		FileName:      i.FileName,
		FilePath:      i.FilePath,
		FileSize:      i.FileSize,
		FileType:      i.FileType,
		UploadTime:    i.UploadTime,
		ExpireTime:    i.ExpireTime,
		Status:        i.Status,
		RemainingTime: remainingTime.Milliseconds(), // 转换为毫秒
		IsExpired:     isExpired,
		CreatedAt:     i.CreatedAt,
		UpdatedAt:     i.UpdatedAt,
	}
}

// ImageResponse 图片响应结构
type ImageResponse struct {
	ID            int       `json:"id"`
	ImageCode     string    `json:"image_code"`
	FileName      string    `json:"file_name"`
	FilePath      string    `json:"file_path"`
	FileSize      int64     `json:"file_size"`
	FileType      string    `json:"file_type"`
	UploadTime    time.Time `json:"upload_time"`
	ExpireTime    time.Time `json:"expire_time"`
	Status        string    `json:"status"`
	RemainingTime int64     `json:"remaining_time"` // 剩余时间（毫秒）
	IsExpired     bool      `json:"is_expired"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// UploadImageRequest 上传图片请求
type UploadImageRequest struct {
	ExpireValue int    `json:"expire_value" binding:"required,min=1"` // 过期时间值
	ExpireUnit  string `json:"expire_unit" binding:"required,oneof=minutes hours days"` // 过期时间单位: minutes, hours, days
}

// ImageListResponse 图片列表响应
type ImageListResponse struct {
	Total int             `json:"total"`
	Items []ImageResponse `json:"items"`
}
