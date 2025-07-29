package routes

import (
	"go-admin/handlers"
	"go-admin/middleware"
	"go-admin/utils"

	"github.com/gin-gonic/gin"
)

// SetupRoutes 设置路由
func SetupRoutes(r *gin.Engine, jwtManager *utils.JWTManager, userService handlers.UserService, imageService handlers.ImageService) {
	// API v1 路由组
	apiV1 := r.Group("/api/v1")
	{
		// 公开路由（无需认证）
		public := apiV1.Group("")
		{
			// 健康检查
			public.GET("/health", healthCheck)

			// 认证相关路由
			authHandler := handlers.NewAuthHandler(jwtManager, userService)
			auth := public.Group("/auth")
			{
				auth.POST("/login", authHandler.Login)
			}

			// 公开的图片访问路由（不需要认证）
			imageHandler := handlers.NewImageHandler(imageService)
			public.GET("/images/code/:code", imageHandler.GetImageByCode)
			public.GET("/images/file/:code", imageHandler.ServeImage)
			public.GET("/images/random", imageHandler.GetRandomImage) // 随机获取图片
			public.GET("/images/task/:taskId", imageHandler.GetTaskStatus) // 查询任务状态
		}

		// 需要认证的路由
		protected := apiV1.Group("")
		protected.Use(middleware.AuthMiddleware(jwtManager))
		{
			// 用户相关路由
			userHandler := handlers.NewUserHandler(userService)
			users := protected.Group("/users")
			{
				users.GET("", userHandler.GetUsers)
				users.GET("/:id", userHandler.GetUser)
				users.POST("", userHandler.CreateUser)
				users.PUT("/:id", userHandler.UpdateUser)
				users.DELETE("/:id", userHandler.DeleteUser)
			}

			// 获取当前用户信息
			authHandler := handlers.NewAuthHandler(jwtManager, userService)
			protected.GET("/auth/profile", authHandler.GetProfile)
			protected.PUT("/auth/profile", userHandler.UpdateProfile)

			// 图片管理路由
			imageHandler := handlers.NewImageHandler(imageService)
			images := protected.Group("/images")
			{
				images.POST("/upload", imageHandler.UploadImage)
				images.GET("", imageHandler.GetImages)
				images.GET("/:id", imageHandler.GetImage)
				images.DELETE("/:id", imageHandler.DeleteImage)
			}
		}
	}
}

// healthCheck 健康检查
func healthCheck(c *gin.Context) {
	utils.Success(c, gin.H{
		"status":  "ok",
		"message": "Go Admin API v1 is running",
	})
}
