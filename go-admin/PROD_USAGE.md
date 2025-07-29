# 生产环境管理脚本使用说明

## 快速开始

```bash
# 进入 go-admin 目录
cd go-admin

# 查看帮助信息
./prod.sh help

# 启动服务
./prod.sh start

# 停止服务
./prod.sh stop

# 更新代码并重启
./prod.sh update
```

## 完整命令列表

| 命令      | 说明                   | 示例                                 |
| --------- | ---------------------- | ------------------------------------ |
| `start`   | 启动所有服务           | `./prod.sh start`                    |
| `stop`    | 停止所有服务           | `./prod.sh stop`                     |
| `restart` | 重启所有服务           | `./prod.sh restart`                  |
| `update`  | 更新代码并重启服务     | `./prod.sh update`                   |
| `status`  | 查看服务状态和资源使用 | `./prod.sh status`                   |
| `logs`    | 查看实时日志           | `./prod.sh logs`                     |
| `build`   | 重新构建镜像           | `./prod.sh build`                    |
| `clean`   | 清理容器和镜像         | `./prod.sh clean`                    |
| `backup`  | 备份数据库             | `./prod.sh backup`                   |
| `restore` | 恢复数据库             | `./prod.sh restore backups/file.sql` |
| `stash`   | 查看暂存的更改         | `./prod.sh stash`                    |
| `help`    | 显示帮助信息           | `./prod.sh help`                     |

## 常用操作流程

### 1. 首次部署

```bash
./prod.sh start
```

### 2. 代码更新

```bash
./prod.sh update
```

### 3. 查看运行状态

```bash
./prod.sh status
```

### 4. 查看日志

```bash
./prod.sh logs
```

### 5. 备份数据库

```bash
./prod.sh backup
```

### 6. 停止服务

```bash
./prod.sh stop
```

## 特性说明

### 🚀 智能启动

- 自动检查 Docker 环境
- 构建并启动所有服务
- 等待服务完全启动
- 显示服务状态和访问地址

### 🔄 一键更新

- 检测当前 Git 分支和未提交更改
- 自动暂存未提交的更改
- 拉取远程分支最新代码
- 清理未使用的镜像资源
- 重新构建镜像并重启服务
- 显示更新结果和暂存恢复提示

### 📊 状态监控

- 显示容器运行状态
- 显示资源使用情况（CPU、内存、网络、磁盘）
- 实时日志查看

### 💾 数据管理

- 自动备份数据库到 `./backups/` 目录
- 支持数据库恢复
- 备份文件按时间戳命名

### 📦 代码管理

- 自动检测 Git 仓库状态
- 智能暂存未提交的更改
- 支持查看和管理暂存
- 自动拉取远程分支代码

### 🧹 资源清理

- 停止并删除容器
- 清理相关镜像
- 清理未使用的 Docker 资源
- 自动清理未使用的镜像（start 和 update 命令）

## 注意事项

1. **首次使用**：确保 Docker 和 docker-compose 已安装
2. **代码更新**：`update` 命令会自动检测并暂存未提交的更改，然后拉取远程代码
3. **暂存管理**：使用 `./prod.sh stash` 查看暂存的更改，使用 `git stash pop` 恢复
4. **数据库备份**：备份文件保存在 `./backups/` 目录
5. **端口冲突**：如果 8081 或 3306 端口被占用，请先停止相关服务
6. **权限问题**：确保脚本有执行权限 `chmod +x prod.sh`

## 故障排除

### Docker 未运行

```bash
# 启动 Docker Desktop 或 Docker 服务
```

### 端口被占用

```bash
# 查看端口占用
lsof -i :8081
lsof -i :3306

# 停止占用端口的进程
```

### 权限不足

```bash
# 给脚本添加执行权限
chmod +x prod.sh
```

### 数据库连接失败

```bash
# 查看 MySQL 容器日志
./prod.sh logs
```
