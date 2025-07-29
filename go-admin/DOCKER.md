# Docker 部署说明

## 快速开始

### 1. 使用启动脚本（推荐）

```bash
# 进入 go-admin 目录
cd go-admin

# 运行启动脚本
./start.sh
```

### 2. 手动使用 Docker Compose

```bash
# 构建并启动所有服务
docker-compose up --build -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 3. 仅构建 Go 服务镜像

```bash
# 构建镜像
docker build -t go-admin:latest .

# 运行容器
docker run -d \
  --name go-admin-api \
  -p 8081:8081 \
  -e DB_HOST=your-mysql-host \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD=root \
  -e DB_NAME=go_admin \
  -e JWT_SECRET=your-secret-key \
  go-admin:latest
```

## 环境变量配置

| 变量名        | 默认值            | 说明           |
| ------------- | ----------------- | -------------- |
| `DB_HOST`     | `localhost`       | MySQL 主机地址 |
| `DB_PORT`     | `3306`            | MySQL 端口     |
| `DB_USER`     | `root`            | MySQL 用户名   |
| `DB_PASSWORD` | `root`            | MySQL 密码     |
| `DB_NAME`     | `go_admin`        | 数据库名       |
| `JWT_SECRET`  | `your-secret-key` | JWT 密钥       |
| `SERVER_HOST` | `localhost`       | 服务器主机     |
| `SERVER_PORT` | `8081`            | 服务器端口     |
| `GIN_MODE`    | `release`         | Gin 运行模式   |

## 服务访问

- **API 服务**: http://localhost:8081
- **MySQL 数据库**: localhost:3306
  - 用户名: `root`
  - 密码: `root`
  - 数据库: `go_admin`

## 常用命令

```bash
# 查看容器状态
docker-compose ps

# 查看服务日志
docker-compose logs -f go-admin
docker-compose logs -f mysql

# 重启服务
docker-compose restart go-admin

# 进入容器
docker-compose exec go-admin sh
docker-compose exec mysql mysql -u root -proot

# 停止所有服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

## 故障排除

### 1. 端口冲突

如果 8081 或 3306 端口被占用，可以修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "8082:8081" # 改为 8082
```

### 2. 数据库连接失败

确保 MySQL 容器已启动：

```bash
docker-compose logs mysql
```

### 3. 权限问题

如果遇到权限问题，可以修改 Dockerfile 中的用户设置：

```dockerfile
# 注释掉用户切换
# USER appuser
```

## 生产环境部署

### 1. 修改环境变量

在生产环境中，请修改以下环境变量：

```yaml
environment:
  JWT_SECRET: your-production-secret-key
  DB_PASSWORD: your-production-db-password
```

### 2. 使用外部数据库

如果使用外部数据库，可以只启动 Go 服务：

```bash
# 修改 docker-compose.yml，注释掉 mysql 服务
# 然后运行
docker-compose up go-admin -d
```

### 3. 健康检查

可以添加健康检查到 docker-compose.yml：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8081/api/v1/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## 镜像优化

当前 Dockerfile 使用了多阶段构建，最终镜像基于 Alpine Linux，大小约为 15-20MB。

如果需要进一步优化，可以考虑：

1. 使用 distroless 镜像
2. 压缩二进制文件
3. 使用 scratch 镜像（需要静态链接）
