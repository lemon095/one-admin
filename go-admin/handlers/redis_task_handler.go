package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"go-admin/config"
	"go-admin/database"
	"go-admin/models"

	"github.com/redis/go-redis/v9"
)

// RedisTaskHandler Redis任务处理器
type RedisTaskHandler struct {
	redisClient  *redis.Client
	imageService ImageService
	ctx          context.Context
	cancel       context.CancelFunc
}

// NewRedisTaskHandler 创建Redis任务处理器
func NewRedisTaskHandler(redisClient *redis.Client, imageService ImageService) *RedisTaskHandler {
	ctx, cancel := context.WithCancel(context.Background())
	return &RedisTaskHandler{
		redisClient:  redisClient,
		imageService: imageService,
		ctx:          ctx,
		cancel:       cancel,
	}
}

// StartTaskProcessor 启动任务处理器
func (h *RedisTaskHandler) StartTaskProcessor() {
	// 启动删除任务处理器
	go h.processDeleteTasks()

	// 启动过期任务处理器
	go h.processExpireTasks()

	log.Println("Redis task processor started")
}

// StopTaskProcessor 停止任务处理器
func (h *RedisTaskHandler) StopTaskProcessor() {
	h.cancel()
	log.Println("Redis task processor stopped")
}

// processDeleteTasks 处理删除任务
func (h *RedisTaskHandler) processDeleteTasks() {
	for {
		select {
		case <-h.ctx.Done():
			return
		default:
			// 从队列中获取任务
			result, err := h.redisClient.BLPop(h.ctx, 1*time.Second, config.ImageDeleteQueue).Result()
			if err != nil {
				if err != redis.Nil {
					log.Printf("Error getting delete task: %v", err)
				}
				continue
			}

			if len(result) < 2 {
				continue
			}

			// 解析任务
			var task models.DeleteTask
			if err := json.Unmarshal([]byte(result[1]), &task); err != nil {
				log.Printf("Error unmarshaling delete task: %v", err)
				continue
			}

			// 处理任务
			h.handleDeleteTask(&task)
		}
	}
}

// processExpireTasks 处理过期任务
func (h *RedisTaskHandler) processExpireTasks() {
	for {
		select {
		case <-h.ctx.Done():
			return
		default:
			// 从队列中获取任务
			result, err := h.redisClient.BLPop(h.ctx, 1*time.Second, config.ImageExpireQueue).Result()
			if err != nil {
				if err != redis.Nil {
					log.Printf("Error getting expire task: %v", err)
				}
				continue
			}

			if len(result) < 2 {
				continue
			}

			// 解析任务
			var task models.DeleteTask
			if err := json.Unmarshal([]byte(result[1]), &task); err != nil {
				log.Printf("Error unmarshaling expire task: %v", err)
				continue
			}

			// 处理任务
			h.handleExpireTask(&task)
		}
	}
}

// handleDeleteTask 处理删除任务
func (h *RedisTaskHandler) handleDeleteTask(task *models.DeleteTask) {
	log.Printf("Processing delete task: %s for image: %s", task.ID, task.ImageCode)

	// 更新任务状态为处理中
	task.Status = config.TaskStatusProcessing
	h.updateTaskStatus(task)

	// 删除文件
	if err := os.Remove(task.FilePath); err != nil && !os.IsNotExist(err) {
		log.Printf("Failed to delete file %s: %v", task.FilePath, err)
		h.handleTaskFailure(task, fmt.Sprintf("Failed to delete file: %v", err))
		return
	}

	// 删除数据库记录
	if err := database.DB.Delete(&models.Image{}, task.ImageID).Error; err != nil {
		log.Printf("Failed to delete database record for image %d: %v", task.ImageID, err)
		h.handleTaskFailure(task, fmt.Sprintf("Failed to delete database record: %v", err))
		return
	}

	// 任务成功
	h.handleTaskSuccess(task, "Image deleted successfully")
	log.Printf("Delete task completed: %s", task.ID)
}

// handleExpireTask 处理过期任务
func (h *RedisTaskHandler) handleExpireTask(task *models.DeleteTask) {
	log.Printf("Processing expire task: %s for image: %s", task.ID, task.ImageCode)

	// 更新任务状态为处理中
	task.Status = config.TaskStatusProcessing
	h.updateTaskStatus(task)

	// 删除文件
	if err := os.Remove(task.FilePath); err != nil && !os.IsNotExist(err) {
		log.Printf("Failed to delete expired file %s: %v", task.FilePath, err)
		h.handleTaskFailure(task, fmt.Sprintf("Failed to delete expired file: %v", err))
		return
	}

	// 更新数据库状态为过期
	if err := database.DB.Model(&models.Image{}).Where("id = ?", task.ImageID).Update("status", "expired").Error; err != nil {
		log.Printf("Failed to update database status for image %d: %v", task.ImageID, err)
		h.handleTaskFailure(task, fmt.Sprintf("Failed to update database status: %v", err))
		return
	}

	// 任务成功
	h.handleTaskSuccess(task, "Image expired successfully")
	log.Printf("Expire task completed: %s", task.ID)
}

// handleTaskSuccess 处理任务成功
func (h *RedisTaskHandler) handleTaskSuccess(task *models.DeleteTask, message string) {
	task.Status = config.TaskStatusCompleted

	result := models.DeleteTaskResult{
		TaskID:      task.ID,
		Success:     true,
		Message:     message,
		CompletedAt: time.Now(),
	}

	// 发布成功结果
	resultJSON, _ := json.Marshal(result)
	h.redisClient.Publish(h.ctx, config.ImageDeleteChannel, resultJSON)

	// 更新任务状态
	h.updateTaskStatus(task)
}

// handleTaskFailure 处理任务失败
func (h *RedisTaskHandler) handleTaskFailure(task *models.DeleteTask, message string) {
	task.RetryCount++

	// 如果重试次数超过3次，标记为失败
	if task.RetryCount >= 3 {
		task.Status = config.TaskStatusFailed

		result := models.DeleteTaskResult{
			TaskID:      task.ID,
			Success:     false,
			Message:     message,
			CompletedAt: time.Now(),
		}

		// 发布失败结果
		resultJSON, _ := json.Marshal(result)
		h.redisClient.Publish(h.ctx, config.ImageDeleteChannel, resultJSON)
	} else {
		// 重新加入队列重试
		task.Status = config.TaskStatusPending
		taskJSON, _ := json.Marshal(task)

		if task.Type == "delete" {
			h.redisClient.RPush(h.ctx, config.ImageDeleteQueue, taskJSON)
		} else {
			h.redisClient.RPush(h.ctx, config.ImageExpireQueue, taskJSON)
		}
	}

	// 更新任务状态
	h.updateTaskStatus(task)
}

// updateTaskStatus 更新任务状态
func (h *RedisTaskHandler) updateTaskStatus(task *models.DeleteTask) {
	taskJSON, _ := json.Marshal(task)
	statusKey := fmt.Sprintf("task:status:%s", task.ID)
	h.redisClient.Set(h.ctx, statusKey, taskJSON, 24*time.Hour)
}
