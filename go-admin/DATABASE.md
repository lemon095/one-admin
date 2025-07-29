# 数据库设置说明

## 1. 安装 MySQL

### macOS (使用 Homebrew)

```bash
brew install mysql
brew services start mysql
```

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql
```

### Windows

下载并安装 MySQL Community Server: https://dev.mysql.com/downloads/mysql/

## 2. 创建数据库

登录 MySQL 并创建数据库：

```sql
mysql -u root -p

CREATE DATABASE go_admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 3. 配置数据库连接

### 方法 1: 环境变量

```bash
export DB_HOST=localhost
export DB_PORT=3306
export DB_USER=root
export DB_PASSWORD=your_password
export DB_NAME=go_admin
```

### 方法 2: 修改代码中的默认值

在 `config/config.go` 文件中修改默认值：

```go
Database: DatabaseConfig{
    Host:     getEnv("DB_HOST", "localhost"),
    Port:     getEnv("DB_PORT", "3306"),
    User:     getEnv("DB_USER", "root"),
    Password: getEnv("DB_PASSWORD", "your_password"), // 修改这里
    DBName:   getEnv("DB_NAME", "go_admin"),
},
```

## 4. 运行应用

```bash
go run main.go
```

应用启动时会自动：

1. 连接到 MySQL 数据库
2. 创建用户表（如果不存在）
3. 插入默认用户数据

## 5. 默认用户

系统会自动创建以下默认用户：

- **管理员账号**

  - 用户名: `admin`
  - 密码: `admin123`
  - 邮箱: `admin@example.com`

- **普通用户账号**
  - 用户名: `user`
  - 密码: `user123`
  - 邮箱: `user@example.com`

## 6. 数据库表结构

### users 表

```sql
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `status` varchar(255) DEFAULT 'active',
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_users_username` (`username`),
  UNIQUE KEY `idx_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 7. 故障排除

### 连接失败

1. 检查 MySQL 服务是否运行
2. 验证数据库连接信息
3. 确保数据库已创建

### 权限错误

```sql
GRANT ALL PRIVILEGES ON go_admin.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
```

### 字符集问题

确保数据库使用 utf8mb4 字符集：

```sql
ALTER DATABASE go_admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```
