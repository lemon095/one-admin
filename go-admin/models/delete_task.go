package models

import (
	"encoding/json"
	"time"
)

// DeleteTask 删除任务
type DeleteTask struct {
	ID         string    `json:"id"`
	Type       string    `json:"type"` // "delete" 或 "expire"
	ImageID    int       `json:"image_id"`
	ImageCode  string    `json:"image_code"`
	FilePath   string    `json:"file_path"`
	CreatedAt  time.Time `json:"created_at"`
	RetryCount int       `json:"retry_count"`
	Status     string    `json:"status"`
}

// DeleteTaskResult 删除任务结果
type DeleteTaskResult struct {
	TaskID      string    `json:"task_id"`
	Success     bool      `json:"success"`
	Message     string    `json:"message"`
	CompletedAt time.Time `json:"completed_at"`
}

// NewDeleteTask 创建删除任务
func NewDeleteTask(taskType string, imageID int, imageCode, filePath string) *DeleteTask {
	return &DeleteTask{
		ID:         generateTaskID(),
		Type:       taskType,
		ImageID:    imageID,
		ImageCode:  imageCode,
		FilePath:   filePath,
		CreatedAt:  time.Now(),
		RetryCount: 0,
		Status:     "pending",
	}
}

// ToJSON 转换为JSON
func (t *DeleteTask) ToJSON() ([]byte, error) {
	return json.Marshal(t)
}

// FromJSON 从JSON解析
func (t *DeleteTask) FromJSON(data []byte) error {
	return json.Unmarshal(data, t)
}

// generateTaskID 生成任务ID
func generateTaskID() string {
	return time.Now().Format("20060102150405") + "-" + generateRandomString(8)
}

// generateRandomString 生成随机字符串
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}
	return string(b)
}
