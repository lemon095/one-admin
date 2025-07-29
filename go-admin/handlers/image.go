package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"go-admin/config"
	"go-admin/models"
	"go-admin/utils"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

// ImageHandler 图片处理器
type ImageHandler struct {
	imageService ImageService
}

// NewImageHandler 创建图片处理器
func NewImageHandler(imageService ImageService) *ImageHandler {
	return &ImageHandler{
		imageService: imageService,
	}
}

// UploadImage 上传图片
func (h *ImageHandler) UploadImage(c *gin.Context) {
	// 获取文件
	file, err := c.FormFile("image")
	if err != nil {
		utils.BadRequest(c, "请选择要上传的图片")
		return
	}

	// 获取过期时间值
	expireValueStr := c.PostForm("expire_value")
	if expireValueStr == "" {
		utils.BadRequest(c, "请设置图片过期时间")
		return
	}

	expireValue, err := strconv.Atoi(expireValueStr)
	if err != nil || expireValue < 1 {
		utils.BadRequest(c, "过期时间值必须大于0")
		return
	}

	// 获取过期时间单位
	expireUnit := c.PostForm("expire_unit")
	if expireUnit == "" {
		utils.BadRequest(c, "请选择过期时间单位")
		return
	}

	// 验证时间单位
	switch expireUnit {
	case "minutes":
		if expireValue > 60*24*365 { // 最多1年
			utils.BadRequest(c, "分钟数不能超过525600分钟（1年）")
			return
		}
	case "hours":
		if expireValue > 24*365 { // 最多1年
			utils.BadRequest(c, "小时数不能超过8760小时（1年）")
			return
		}
	case "days":
		if expireValue > 365 { // 最多1年
			utils.BadRequest(c, "天数不能超过365天")
			return
		}
	default:
		utils.BadRequest(c, "无效的时间单位，支持：minutes, hours, days")
		return
	}

	// 上传图片
	image, err := h.imageService.UploadImage(file, expireValue, expireUnit)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	utils.SuccessWithMessage(c, "图片上传成功", image.ToResponse())
}

// GetImage 获取图片信息
func (h *ImageHandler) GetImage(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "无效的图片ID")
		return
	}

	image, err := h.imageService.GetImageByID(id)
	if err != nil {
		utils.NotFound(c, "图片不存在")
		return
	}

	utils.SuccessWithMessage(c, "获取图片信息成功", image.ToResponse())
}

// GetImageByCode 根据图片码获取图片
func (h *ImageHandler) GetImageByCode(c *gin.Context) {
	imageCode := c.Param("code")
	if imageCode == "" {
		utils.BadRequest(c, "图片码不能为空")
		return
	}

	image, err := h.imageService.GetImageByCode(imageCode)
	if err != nil {
		utils.NotFound(c, "图片不存在")
		return
	}

	utils.SuccessWithMessage(c, "获取图片信息成功", image.ToResponse())
}

// GetImages 获取图片列表
func (h *ImageHandler) GetImages(c *gin.Context) {
	// 获取分页参数
	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "10")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}

	pageSize, err := strconv.Atoi(pageSizeStr)
	if err != nil || pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	// 获取图片列表
	result, err := h.imageService.GetAllImages(page, pageSize)
	if err != nil {
		utils.InternalServerError(c, "获取图片列表失败")
		return
	}

	utils.SuccessWithMessage(c, "获取图片列表成功", result)
}

// DeleteImage 删除图片
func (h *ImageHandler) DeleteImage(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "无效的图片ID")
		return
	}

	if err := h.imageService.DeleteImage(id); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	utils.SuccessWithMessage(c, "图片删除成功", nil)
}

// ServeImage 提供图片文件服务
func (h *ImageHandler) ServeImage(c *gin.Context) {
	imageCode := c.Param("code")
	if imageCode == "" {
		utils.BadRequest(c, "图片码不能为空")
		return
	}

	image, err := h.imageService.GetImageByCode(imageCode)
	if err != nil {
		utils.NotFound(c, "图片不存在")
		return
	}

	// 检查图片是否过期
	response := image.ToResponse()
	if response.IsExpired {
		utils.BadRequest(c, "图片已过期")
		return
	}

	// 提供文件下载
	c.File(image.FilePath)
}

// GetRandomImage 随机获取图片
func (h *ImageHandler) GetRandomImage(c *gin.Context) {
	// 获取随机图片
	image, err := h.imageService.GetRandomImage()
	if err != nil {
		utils.NotFound(c, err.Error())
		return
	}

	// 计算访问截止时间（从请求开始往后5分钟）
	accessExpireTime := time.Now().Add(5 * time.Minute)

	// 构建响应数据
	response := map[string]interface{}{
		"id":                 image.ID,
		"image_code":         image.ImageCode,
		"file_name":          image.FileName,
		"file_size":          image.FileSize,
		"file_type":          image.FileType,
		"upload_time":        image.UploadTime,
		"expire_time":        image.ExpireTime,
		"status":             image.Status,
		"access_expire_time": accessExpireTime,                                       // 访问截止时间
		"image_url":          fmt.Sprintf("/api/v1/images/file/%s", image.ImageCode), // 图片访问URL
	}

	utils.SuccessWithMessage(c, "获取随机图片成功", response)
}

// GetTaskStatus 获取任务状态
func (h *ImageHandler) GetTaskStatus(c *gin.Context) {
	taskID := c.Param("taskId")
	if taskID == "" {
		utils.BadRequest(c, "任务ID不能为空")
		return
	}

	// 从Redis获取任务状态
	ctx := context.Background()
	statusKey := fmt.Sprintf("task:status:%s", taskID)
	taskJSON, err := config.RedisClient.Get(ctx, statusKey).Result()
	if err != nil {
		if err == redis.Nil {
			utils.NotFound(c, "任务不存在")
		} else {
			utils.InternalServerError(c, "获取任务状态失败")
		}
		return
	}

	var task models.DeleteTask
	if err := json.Unmarshal([]byte(taskJSON), &task); err != nil {
		utils.InternalServerError(c, "解析任务状态失败")
		return
	}

	utils.SuccessWithMessage(c, "获取任务状态成功", task)
}
