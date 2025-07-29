# Go Admin 生产环境管理脚本使用指南

## 📋 概述

`prod.sh` 是一个统一的生产环境管理脚本，支持两种运行模式：

- **生产环境 (prod)**：启动所有服务（Go + MySQL + Redis）
- **开发环境 (dev)**：只启动 Go 服务（连接本地数据库）

## 🚀 快速开始

### 基本用法

```bash
# 给脚本执行权限
chmod +x prod.sh

# 生产环境 - 启动所有服务
./prod.sh prod start

# 开发环境 - 只启动Go服务
./prod.sh dev start

# 查看帮助
./prod.sh help
```

## 🔧 命令详解

### 环境参数

| 环境   | 说明                                          |
| ------ | --------------------------------------------- |
| `prod` | 生产环境 - 启动所有服务（Go + MySQL + Redis） |
| `dev`  | 开发环境 - 只启动 Go 服务（连接本地数据库）   |

### 管理命令

| 命令      | 说明           | 示例                     |
| --------- | -------------- | ------------------------ |
| `start`   | 启动服务       | `./prod.sh prod start`   |
| `stop`    | 停止服务       | `./prod.sh prod stop`    |
| `restart` | 重启服务       | `./prod.sh prod restart` |
| `update`  | 更新代码并重启 | `./prod.sh prod update`  |
| `status`  | 查看服务状态   | `./prod.sh prod status`  |
| `logs`    | 查看服务日志   | `./prod.sh prod logs`    |
| `build`   | 重新构建镜像   | `./prod.sh prod build`   |
| `clean`   | 清理容器和镜像 | `./prod.sh prod clean`   |
| `backup`  | 备份数据库     | `./prod.sh prod backup`  |
| `restore` | 恢复数据库     | `./prod.sh prod restore` |
| `stash`   | 查看暂存的更改 | `./prod.sh stash`        |

## 🌍 环境配置

### 生产环境 (prod)

**启动的服务：**

- Go Admin API 服务
- MySQL 数据库容器
- Redis 缓存容器

**数据库配置：**

- MySQL 密码：`shgytywe!#%65926328`
- Redis 密码：`Test!#$1234.hjdgsag`
- 时区：`Asia/Shanghai`

**网络配置：**

- 网络名：`go-admin-network`
- MySQL 端口：`3306`
- Redis 端口：`6379`
- API 端口：`8081`

### 开发环境 (dev)

**启动的服务：**

- 只启动 Go Admin API 服务

**数据库连接：**

- 连接本地 MySQL 数据库
- 连接本地 Redis 服务
- 使用 `host.docker.internal` 访问宿主机

## 📊 使用场景

### 生产环境使用

```bash
# 1. 启动生产环境
./prod.sh prod start

# 2. 查看状态
./prod.sh prod status

# 3. 查看日志
./prod.sh prod logs

# 4. 更新代码
./prod.sh prod update

# 5. 停止服务
./prod.sh prod stop
```

### 开发环境使用

```bash
# 1. 确保本地数据库运行
# MySQL: localhost:3306
# Redis: localhost:6379

# 2. 启动开发环境
./prod.sh dev start

# 3. 查看状态
./prod.sh dev status

# 4. 查看日志
./prod.sh dev logs

# 5. 停止服务
./prod.sh dev stop
```

## 🔄 更新流程

### 自动更新（推荐）

```bash
# 更新代码并重启服务
./prod.sh prod update
```

**更新过程：**

1. 检查 Git 仓库状态
2. 暂存未提交的更改
3. 拉取最新代码
4. 停止当前服务
5. 清理未使用的镜像
6. 重新构建并启动服务

### 手动更新

```bash
# 1. 停止服务
./prod.sh prod stop

# 2. 拉取代码
git pull origin main

# 3. 重新构建
./prod.sh prod build

# 4. 启动服务
./prod.sh prod start
```

## 📋 日志管理

### 查看日志

```bash
# 生产环境日志
./prod.sh prod logs

# 开发环境日志
./prod.sh dev logs
```

**日志选项：**

- Go Admin 服务日志
- MySQL 数据库日志（仅生产环境）
- Redis 缓存日志（仅生产环境）
- 所有服务日志

### 日志位置

- **Go Admin 日志**：`docker logs go-admin-api` 或 `docker logs go-admin-api-dev`
- **MySQL 日志**：`docker logs go-admin-mysql`
- **Redis 日志**：`docker logs go-admin-redis`

## 💾 数据管理

### 备份数据库

```bash
# 备份生产环境数据库
./prod.sh prod backup
```

**备份文件位置：** `./backups/mysql_backup_YYYYMMDD_HHMMSS.sql`

### 恢复数据库

```bash
# 恢复生产环境数据库
./prod.sh prod restore
```

**注意事项：**

- 恢复操作会覆盖现有数据
- 需要确认操作才能执行
- 开发环境需要手动备份/恢复

## 🧹 清理操作

### 清理容器和镜像

```bash
# 清理生产环境
./prod.sh prod clean

# 清理开发环境
./prod.sh dev clean
```

**清理内容：**

- 停止并删除容器
- 删除相关镜像
- 删除数据卷（生产环境）
- 删除网络（生产环境）

### 清理暂存

```bash
# 查看暂存的更改
./prod.sh stash

# 恢复暂存（手动操作）
git stash pop
```

## 🔍 故障排除

### 常见问题

1. **端口冲突**

   ```bash
   # 检查端口占用
   lsof -i :8081
   lsof -i :3306
   lsof -i :6379
   ```

2. **容器启动失败**

   ```bash
   # 查看容器日志
   ./prod.sh prod logs
   ./prod.sh dev logs
   ```

3. **数据库连接失败**

   ```bash
   # 检查数据库状态
   ./prod.sh prod status

   # 检查网络连接
   docker network ls
   docker network inspect go-admin-network
   ```

4. **镜像构建失败**
   ```bash
   # 重新构建镜像
   ./prod.sh prod build
   ./prod.sh dev build
   ```

### 调试模式

```bash
# 查看详细日志
docker-compose -f docker-compose.yml --profile prod logs -f

# 进入容器调试
docker exec -it go-admin-api bash
docker exec -it go-admin-mysql bash
docker exec -it go-admin-redis sh
```

## 📞 连接信息

### 生产环境

- **API 服务**：http://localhost:8081
- **MySQL**：localhost:3306 (root/shgytywe!#%65926328)
- **Redis**：localhost:6379 (密码: Test!#$1234.hjdgsag)

### 开发环境

- **API 服务**：http://localhost:8081
- **MySQL**：本地数据库
- **Redis**：本地 Redis

## 🎯 最佳实践

1. **环境隔离**：生产环境使用容器数据库，开发环境使用本地数据库
2. **定期备份**：使用 `./prod.sh prod backup` 定期备份数据
3. **日志监控**：定期检查服务日志，及时发现问题
4. **资源清理**：定期使用 `clean` 命令清理未使用的资源
5. **版本控制**：使用 `update` 命令进行代码更新，自动处理暂存

## 📚 相关文档

- [Docker Compose 官方文档](https://docs.docker.com/compose/)
- [Go Admin 项目文档](./README.md)
- [数据库部署指南](./DB_DEPLOYMENT.md)
