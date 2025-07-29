# Go Admin Backend

基于 Gin 框架的 Go 后端 API 服务，支持 JWT 认证和统一的 API 规范。

## 功能特性

- 🚀 基于 Gin 框架的高性能 Web 服务
- 🔒 JWT Token 认证（有效期 1 天）
- 📝 RESTful API 设计（统一前缀 `/api/v1`）
- 🛡️ 中间件支持（日志、恢复、认证）
- 👥 用户管理 API
- 🔐 登录认证系统

## 快速开始

### 环境要求

- Go 1.21+

### 安装依赖

```bash
go mod tidy
```

### 运行服务

```bash
go run main.go
```

服务将在 `http://localhost:8080` 启动

### 构建

```bash
go build -o go-admin main.go
```

## API 接口规范

### 基础信息

- **基础 URL**: `http://localhost:8080/api/v1`
- **认证方式**: Bearer Token (JWT)
- **Token 有效期**: 24 小时

### 公开接口（无需认证）

#### 健康检查

- `GET /api/v1/health` - 服务健康状态

#### 用户认证

- `POST /api/v1/auth/login` - 用户登录

**请求示例**:

```json
{
  "username": "admin",
  "password": "admin123"
}
```

**响应示例**:

```json
{
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com"
    }
  }
}
```

### 受保护接口（需要认证）

所有受保护的接口都需要在请求头中包含有效的 JWT Token：

```
Authorization: Bearer <your-jwt-token>
```

#### 用户管理

- `GET /api/v1/users` - 获取用户列表
- `GET /api/v1/users/:id` - 获取单个用户
- `POST /api/v1/users` - 创建用户
- `PUT /api/v1/users/:id` - 更新用户
- `DELETE /api/v1/users/:id` - 删除用户

#### 用户信息

- `GET /api/v1/auth/profile` - 获取当前用户信息

## 默认用户

系统预置了两个测试用户：

1. **管理员账号**

   - 用户名: `admin`
   - 密码: `admin123`
   - 邮箱: `admin@example.com`

2. **普通用户账号**
   - 用户名: `user`
   - 密码: `user123`
   - 邮箱: `user@example.com`

## 项目结构

```
go-admin/
├── main.go          # 主入口文件
├── go.mod           # Go 模块文件
├── go.sum           # 依赖校验文件
└── README.md        # 项目说明
```

## 技术实现

### JWT 认证流程

1. **登录**: 用户提供用户名和密码
2. **验证**: 服务器验证用户凭据
3. **生成 Token**: 验证成功后生成 JWT Token（有效期 24 小时）
4. **返回 Token**: 将 Token 返回给客户端
5. **后续请求**: 客户端在请求头中携带 Token
6. **验证 Token**: 服务器验证 Token 的有效性

### 中间件

- **认证中间件**: 验证 JWT Token 的有效性
- **CORS 中间件**: 处理跨域请求
- **日志中间件**: 记录请求日志
- **恢复中间件**: 处理 panic 恢复

## 开发计划

- [ ] 数据库集成 (MySQL/PostgreSQL)
- [ ] 密码加密存储
- [ ] 权限管理系统
- [ ] 角色管理
- [ ] 菜单管理
- [ ] 系统设置
- [ ] 日志系统
- [ ] 配置管理
- [ ] 文件上传
- [ ] 数据导出
