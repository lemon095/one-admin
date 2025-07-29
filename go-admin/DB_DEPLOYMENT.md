# MySQL 和 Redis 部署指南

## 📋 概述

本项目提供了分离式的数据库部署方案，将 MySQL 和 Redis 独立部署，Go 服务单独部署，提高启动速度和资源利用率。

## 🚀 快速开始

### 1. 部署数据库服务

```bash
# 给脚本执行权限
chmod +x deploy-db.sh

# 启动MySQL和Redis
./deploy-db.sh start

# 查看服务状态
./deploy-db.sh status
```

### 2. 部署 Go 服务

```bash
# 使用生产环境配置启动Go服务
docker compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker compose -f docker-compose.prod.yml ps
```

## 📊 服务配置

### MySQL 配置

- **容器名**: `mysql-server`
- **端口**: `3306`
- **密码**: `shgytywe!#%65926328`
- **数据库**: `go_admin`
- **时区**: `Asia/Shanghai`
- **字符集**: `utf8mb4`

### Redis 配置

- **容器名**: `redis-server`
- **端口**: `6379`
- **密码**: `Test!#$1234.hjdgsag`
- **时区**: `Asia/Shanghai`
- **订阅支持**: 已启用
- **持久化**: AOF + RDB

## 🔧 管理命令

### 数据库服务管理

```bash
# 启动服务
./deploy-db.sh start

# 停止服务
./deploy-db.sh stop

# 重启服务
./deploy-db.sh restart

# 查看状态
./deploy-db.sh status

# 查看日志
./deploy-db.sh logs

# 备份数据库
./deploy-db.sh backup

# 恢复数据库
./deploy-db.sh restore

# 清理所有数据（危险操作）
./deploy-db.sh clean
```

### Go 服务管理

```bash
# 启动Go服务
docker compose -f docker-compose.prod.yml up -d

# 停止Go服务
docker compose -f docker-compose.prod.yml down

# 重启Go服务
docker compose -f docker-compose.prod.yml restart

# 查看Go服务日志
docker compose -f docker-compose.prod.yml logs -f go-admin

# 重新构建并启动
docker compose -f docker-compose.prod.yml up --build -d
```

## 🌐 网络配置

- **网络名**: `db-network`
- **MySQL 容器**: `mysql-server`
- **Redis 容器**: `redis-server`
- **Go 服务**: `go-admin-prod`

所有服务都在同一个 Docker 网络中，可以通过容器名互相访问。

## 📁 数据持久化

### MySQL 数据

- **数据卷**: `mysql_data`
- **配置文件**: `./mysql/conf/my.cnf`
- **日志文件**: `./mysql/logs/`

### Redis 数据

- **数据卷**: `redis_data`
- **配置文件**: `./redis/conf/redis.conf`
- **持久化**: AOF + RDB

### Go 服务数据

- **上传文件**: `./uploads/`
- **图片文件**: `./uploads/images/`

## 🔒 安全配置

### MySQL 安全

- 强密码策略
- 限制最大连接数
- 慢查询日志
- 错误日志记录

### Redis 安全

- 密码认证
- 内存限制
- 键过期事件通知
- 持久化保护

## 📈 性能优化

### MySQL 优化

- InnoDB 缓冲池: 256MB
- 查询缓存: 32MB
- 连接池: 1000
- 慢查询阈值: 2 秒

### Redis 优化

- 最大内存: 256MB
- 内存策略: allkeys-lru
- AOF 重写: 自动
- 持久化: 混合模式

## 🚨 故障排除

### 常见问题

1. **端口冲突**

   ```bash
   # 检查端口占用
   lsof -i :3306
   lsof -i :6379
   lsof -i :8081
   ```

2. **容器启动失败**

   ```bash
   # 查看容器日志
   docker logs mysql-server
   docker logs redis-server
   docker logs go-admin-prod
   ```

3. **网络连接问题**

   ```bash
   # 检查网络
   docker network ls
   docker network inspect db-network
   ```

4. **数据丢失**
   ```bash
   # 检查数据卷
   docker volume ls
   docker volume inspect mysql_data
   docker volume inspect redis_data
   ```

### 日志位置

- **MySQL 日志**: `./mysql/logs/`
- **Redis 日志**: `docker logs redis-server`
- **Go 服务日志**: `docker logs go-admin-prod`

## 🔄 备份和恢复

### 自动备份

```bash
# 创建定时备份
crontab -e

# 添加以下行（每天凌晨2点备份）
0 2 * * * /path/to/go-admin/deploy-db.sh backup
```

### 手动备份

```bash
# 备份数据库
./deploy-db.sh backup

# 恢复数据库
./deploy-db.sh restore
```

## 📞 连接信息

### 开发环境连接

```bash
# MySQL
mysql -h localhost -P 3306 -u root -p'shgytywe!#%65926328'

# Redis
redis-cli -h localhost -p 6379 -a 'Test!#$1234.hjdgsag'
```

### 容器内连接

```bash
# MySQL
docker exec -it mysql-server mysql -u root -p

# Redis
docker exec -it redis-server redis-cli -a 'Test!#$1234.hjdgsag'
```

## 🎯 最佳实践

1. **定期备份**: 设置自动备份策略
2. **监控日志**: 定期检查服务日志
3. **资源监控**: 监控 CPU、内存、磁盘使用情况
4. **安全更新**: 定期更新 Docker 镜像
5. **测试恢复**: 定期测试备份恢复流程

## 📚 相关文档

- [Docker 官方文档](https://docs.docker.com/)
- [MySQL 官方文档](https://dev.mysql.com/doc/)
- [Redis 官方文档](https://redis.io/documentation)
- [Go Admin 项目文档](./README.md)
