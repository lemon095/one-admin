# One Admin - 全栈管理后台系统

一个基于 Go + Vue 3 的现代化全栈管理后台系统。

## 项目结构

```
one-admin/
├── go-admin/          # Go 后端服务
│   ├── main.go        # 主入口文件
│   ├── go.mod         # Go 模块文件
│   └── README.md      # 后端说明文档
├── vue-admin/         # Vue 前端应用
│   ├── src/           # 源代码目录
│   ├── package.json   # 前端依赖配置
│   └── README.md      # 前端说明文档
└── .gitignore         # Git 忽略文件
```

## 技术栈

### 后端 (go-admin)
- 🚀 **Go** - 高性能编程语言
- 🌐 **Gin** - Web 框架
- 🔒 **CORS** - 跨域支持
- 📝 **RESTful API** - 标准 API 设计

### 前端 (vue-admin)
- 🎯 **Vue 3** - 渐进式 JavaScript 框架
- 🔧 **TypeScript** - 类型安全的 JavaScript
- 🎨 **Element Plus** - Vue 3 组件库
- 🚀 **Vite** - 下一代前端构建工具
- 📱 **Vue Router** - 路由管理
- 🗃️ **Pinia** - 状态管理

## 快速开始

### 1. 启动后端服务

```bash
cd go-admin
go run main.go
```

后端服务将在 `http://localhost:8080` 启动

### 2. 启动前端应用

```bash
cd vue-admin
npm run dev
```

前端应用将在 `http://localhost:3000` 启动

### 3. 访问系统

- 前端地址：http://localhost:3000
- 后端 API：http://localhost:8080/api

## 功能特性

- 🔐 用户认证系统
- 👥 用户管理
- 📊 数据仪表盘
- 🎨 现代化 UI 设计
- 📱 响应式布局
- 🔍 搜索和筛选
- 📄 分页功能
- 🎯 表单验证

## API 接口

### 健康检查
- `GET /api/health` - 服务健康状态

### 用户管理
- `GET /api/users` - 获取用户列表
- `GET /api/users/:id` - 获取单个用户
- `POST /api/users` - 创建用户
- `PUT /api/users/:id` - 更新用户
- `DELETE /api/users/:id` - 删除用户

## 开发指南

### 后端开发
1. 进入 `go-admin` 目录
2. 修改 `main.go` 添加新的 API 接口
3. 运行 `go run main.go` 启动服务

### 前端开发
1. 进入 `vue-admin` 目录
2. 在 `src/views/` 下创建新页面
3. 在 `src/router/index.ts` 添加路由
4. 运行 `npm run dev` 启动开发服务器

## 部署

### 后端部署
```bash
cd go-admin
go build -o go-admin main.go
./go-admin
```

### 前端部署
```bash
cd vue-admin
npm run build
# 将 dist 目录部署到 Web 服务器
```

## 开发计划

- [ ] 数据库集成 (MySQL/PostgreSQL)
- [ ] 用户认证和授权
- [ ] 权限管理系统
- [ ] 角色管理
- [ ] 菜单管理
- [ ] 系统设置
- [ ] 日志管理
- [ ] 文件上传
- [ ] 数据导出
- [ ] 主题切换
- [ ] 国际化支持