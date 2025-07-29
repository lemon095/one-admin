package main

import (
	"log"

	"go-admin/config"
	"go-admin/database"
	"go-admin/handlers"
	"go-admin/middleware"
	"go-admin/routes"
	"go-admin/utils"

	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg := config.LoadConfig()

	// 创建 Gin 引擎
	r := gin.Default()

	// 添加中间件
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(middleware.CORSMiddleware())

	// 初始化Redis
	if err := config.InitRedis(&cfg.Redis); err != nil {
		log.Fatal("Failed to initialize Redis:", err)
	}
	defer config.CloseRedis()

	// 创建JWT管理器
	jwtManager := utils.NewJWTManager(cfg.JWT.Secret, cfg.JWT.ExpireTime)

	// 初始化数据库
	if err := database.InitDatabase(cfg); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// 创建用户服务
	userService := handlers.NewUserService()

	// 创建图片服务
	imageService := handlers.NewImageService(config.RedisClient)

	// 创建Redis任务处理器
	taskHandler := handlers.NewRedisTaskHandler(config.RedisClient, imageService)
	taskHandler.StartTaskProcessor()
	defer taskHandler.StopTaskProcessor()

	// 启动图片清理调度器
	imageService.StartCleanupScheduler()

	// 设置路由
	routes.SetupRoutes(r, jwtManager, userService, imageService)

	// 启动服务器
	addr := cfg.Server.Host + ":" + cfg.Server.Port
	log.Printf("Go Admin API server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
 