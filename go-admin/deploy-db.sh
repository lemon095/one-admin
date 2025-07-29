#!/bin/bash

# MySQL和Redis一键部署脚本
# 支持密码配置、时区设置和Redis订阅

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
MYSQL_PASSWORD="shgytywe!#%65926328"
REDIS_PASSWORD="Test!#$1234.hjdgsag"
MYSQL_PORT="3306"
REDIS_PORT="6379"
MYSQL_CONTAINER_NAME="mysql-server"
REDIS_CONTAINER_NAME="redis-server"
NETWORK_NAME="db-network"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}MySQL和Redis一键部署脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  start     启动MySQL和Redis服务"
    echo "  stop      停止MySQL和Redis服务"
    echo "  restart   重启MySQL和Redis服务"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  clean     清理容器和数据（危险操作）"
    echo "  backup    备份数据库"
    echo "  restore   恢复数据库"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start    # 启动服务"
    echo "  $0 status   # 查看状态"
    echo "  $0 stop     # 停止服务"
}

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker未安装，请先安装Docker${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker服务未启动，请先启动Docker${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker已安装并运行${NC}"
}

# 创建网络
create_network() {
    if ! docker network ls | grep -q $NETWORK_NAME; then
        echo -e "${YELLOW}🌐 创建Docker网络: $NETWORK_NAME${NC}"
        docker network create $NETWORK_NAME
    else
        echo -e "${GREEN}✅ 网络 $NETWORK_NAME 已存在${NC}"
    fi
}

# 启动MySQL服务
start_mysql() {
    echo -e "${BLUE}🐬 启动MySQL服务...${NC}"
    
    # 检查容器是否已存在
    if docker ps -a --format "table {{.Names}}" | grep -q $MYSQL_CONTAINER_NAME; then
        echo -e "${YELLOW}⚠️  MySQL容器已存在，正在启动...${NC}"
        docker start $MYSQL_CONTAINER_NAME
    else
        echo -e "${YELLOW}📦 创建并启动MySQL容器...${NC}"
        docker run -d \
            --name $MYSQL_CONTAINER_NAME \
            --network $NETWORK_NAME \
            -p $MYSQL_PORT:3306 \
            -e MYSQL_ROOT_PASSWORD="$MYSQL_PASSWORD" \
            -e MYSQL_DATABASE=go_admin \
            -e TZ=Asia/Shanghai \
            -v mysql_data:/var/lib/mysql \
            -v $(pwd)/mysql/conf:/etc/mysql/conf.d \
            -v $(pwd)/mysql/logs:/var/log/mysql \
            --restart unless-stopped \
            mysql:8.0 \
            --default-authentication-plugin=mysql_native_password \
            --character-set-server=utf8mb4 \
            --collation-server=utf8mb4_unicode_ci \
            --default-time-zone='+8:00'
    fi
    
    echo -e "${GREEN}✅ MySQL服务启动成功${NC}"
    echo -e "${BLUE}📋 MySQL连接信息:${NC}"
    echo -e "   主机: localhost"
    echo -e "   端口: $MYSQL_PORT"
    echo -e "   用户名: root"
    echo -e "   密码: $MYSQL_PASSWORD"
    echo -e "   数据库: go_admin"
}

# 启动Redis服务
start_redis() {
    echo -e "${BLUE}🔴 启动Redis服务...${NC}"
    
    # 检查容器是否已存在
    if docker ps -a --format "table {{.Names}}" | grep -q $REDIS_CONTAINER_NAME; then
        echo -e "${YELLOW}⚠️  Redis容器已存在，正在启动...${NC}"
        docker start $REDIS_CONTAINER_NAME
    else
        echo -e "${YELLOW}📦 创建并启动Redis容器...${NC}"
        docker run -d \
            --name $REDIS_CONTAINER_NAME \
            --network $NETWORK_NAME \
            -p $REDIS_PORT:6379 \
            -e TZ=Asia/Shanghai \
            -v redis_data:/data \
            -v $(pwd)/redis/conf/redis.conf:/usr/local/etc/redis/redis.conf \
            --restart unless-stopped \
            redis:7-alpine \
            redis-server /usr/local/etc/redis/redis.conf --requirepass "$REDIS_PASSWORD"
    fi
    
    echo -e "${GREEN}✅ Redis服务启动成功${NC}"
    echo -e "${BLUE}📋 Redis连接信息:${NC}"
    echo -e "   主机: localhost"
    echo -e "   端口: $REDIS_PORT"
    echo -e "   密码: $REDIS_PASSWORD"
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 开始启动MySQL和Redis服务...${NC}"
    
    check_docker
    create_network
    
    # 创建配置目录
    mkdir -p mysql/conf mysql/logs redis/conf
    
    # 创建MySQL配置文件
    cat > mysql/conf/my.cnf << 'EOF'
[mysqld]
default-time-zone='+8:00'
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
max_connections=1000
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT
query_cache_type=1
query_cache_size=32M
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2
log_error=/var/log/mysql/error.log
log_queries_not_using_indexes=1

[mysql]
default-character-set=utf8mb4

[client]
default-character-set=utf8mb4
EOF

    # 创建Redis配置文件
    cat > redis/conf/redis.conf << 'EOF'
# Redis配置文件
bind 0.0.0.0
port 6379
timeout 300
tcp-keepalive 60
loglevel notice
logfile ""
databases 16

# 持久化配置
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# AOF配置
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# 内存配置
maxmemory 256mb
maxmemory-policy allkeys-lru

# 安全配置
requirepass Test!#$1234.hjdgsag

# 时区配置
timezone Asia/Shanghai

# 订阅配置
notify-keyspace-events Ex
EOF

    start_mysql
    start_redis
    
    echo -e "${GREEN}🎉 所有服务启动完成！${NC}"
    echo ""
    echo -e "${BLUE}📊 服务状态:${NC}"
    docker ps --filter "name=$MYSQL_CONTAINER_NAME|$REDIS_CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}🛑 停止MySQL和Redis服务...${NC}"
    
    if docker ps --format "table {{.Names}}" | grep -q $MYSQL_CONTAINER_NAME; then
        docker stop $MYSQL_CONTAINER_NAME
        echo -e "${GREEN}✅ MySQL服务已停止${NC}"
    else
        echo -e "${YELLOW}⚠️  MySQL服务未运行${NC}"
    fi
    
    if docker ps --format "table {{.Names}}" | grep -q $REDIS_CONTAINER_NAME; then
        docker stop $REDIS_CONTAINER_NAME
        echo -e "${GREEN}✅ Redis服务已停止${NC}"
    else
        echo -e "${YELLOW}⚠️  Redis服务未运行${NC}"
    fi
}

# 重启服务
restart_services() {
    echo -e "${YELLOW}🔄 重启MySQL和Redis服务...${NC}"
    stop_services
    sleep 2
    start_services
}

# 查看服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态:${NC}"
    echo ""
    
    # MySQL状态
    if docker ps --format "table {{.Names}}" | grep -q $MYSQL_CONTAINER_NAME; then
        echo -e "${GREEN}✅ MySQL: 运行中${NC}"
        echo -e "   容器名: $MYSQL_CONTAINER_NAME"
        echo -e "   端口: $MYSQL_PORT"
        echo -e "   网络: $NETWORK_NAME"
    else
        echo -e "${RED}❌ MySQL: 未运行${NC}"
    fi
    
    echo ""
    
    # Redis状态
    if docker ps --format "table {{.Names}}" | grep -q $REDIS_CONTAINER_NAME; then
        echo -e "${GREEN}✅ Redis: 运行中${NC}"
        echo -e "   容器名: $REDIS_CONTAINER_NAME"
        echo -e "   端口: $REDIS_PORT"
        echo -e "   网络: $NETWORK_NAME"
    else
        echo -e "${RED}❌ Redis: 未运行${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔗 连接信息:${NC}"
    echo -e "   MySQL: localhost:$MYSQL_PORT (root/$MYSQL_PASSWORD)"
    echo -e "   Redis: localhost:$REDIS_PORT (密码: $REDIS_PASSWORD)"
}

# 查看服务日志
show_logs() {
    echo -e "${BLUE}📋 选择要查看的日志:${NC}"
    echo "1) MySQL日志"
    echo "2) Redis日志"
    echo "3) 所有日志"
    read -p "请选择 (1-3): " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}📋 MySQL日志:${NC}"
            docker logs $MYSQL_CONTAINER_NAME
            ;;
        2)
            echo -e "${YELLOW}📋 Redis日志:${NC}"
            docker logs $REDIS_CONTAINER_NAME
            ;;
        3)
            echo -e "${YELLOW}📋 MySQL日志:${NC}"
            docker logs $MYSQL_CONTAINER_NAME
            echo ""
            echo -e "${YELLOW}📋 Redis日志:${NC}"
            docker logs $REDIS_CONTAINER_NAME
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            ;;
    esac
}

# 清理容器和数据
clean_services() {
    echo -e "${RED}⚠️  危险操作！这将删除所有容器和数据！${NC}"
    read -p "确定要继续吗？(输入 'yes' 确认): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}🧹 清理容器和数据...${NC}"
        
        # 停止并删除容器
        docker stop $MYSQL_CONTAINER_NAME $REDIS_CONTAINER_NAME 2>/dev/null || true
        docker rm $MYSQL_CONTAINER_NAME $REDIS_CONTAINER_NAME 2>/dev/null || true
        
        # 删除网络
        docker network rm $NETWORK_NAME 2>/dev/null || true
        
        # 删除数据卷
        docker volume rm mysql_data redis_data 2>/dev/null || true
        
        # 删除配置文件
        rm -rf mysql redis
        
        echo -e "${GREEN}✅ 清理完成${NC}"
    else
        echo -e "${YELLOW}❌ 操作已取消${NC}"
    fi
}

# 备份数据库
backup_database() {
    echo -e "${BLUE}💾 备份MySQL数据库...${NC}"
    
    if ! docker ps --format "table {{.Names}}" | grep -q $MYSQL_CONTAINER_NAME; then
        echo -e "${RED}❌ MySQL服务未运行${NC}"
        return 1
    fi
    
    # 创建备份目录
    mkdir -p backups
    BACKUP_FILE="backups/mysql_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    # 执行备份
    docker exec $MYSQL_CONTAINER_NAME mysqldump -u root -p"$MYSQL_PASSWORD" --all-databases > "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 数据库备份成功: $BACKUP_FILE${NC}"
    else
        echo -e "${RED}❌ 数据库备份失败${NC}"
    fi
}

# 恢复数据库
restore_database() {
    echo -e "${BLUE}📥 恢复MySQL数据库...${NC}"
    
    if ! docker ps --format "table {{.Names}}" | grep -q $MYSQL_CONTAINER_NAME; then
        echo -e "${RED}❌ MySQL服务未运行${NC}"
        return 1
    fi
    
    # 列出备份文件
    if [ ! -d "backups" ] || [ -z "$(ls -A backups 2>/dev/null)" ]; then
        echo -e "${RED}❌ 没有找到备份文件${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📋 可用的备份文件:${NC}"
    ls -la backups/*.sql
    
    read -p "请输入要恢复的备份文件路径: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}❌ 备份文件不存在${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⚠️  这将覆盖现有数据！${NC}"
    read -p "确定要继续吗？(输入 'yes' 确认): " confirm
    
    if [ "$confirm" = "yes" ]; then
        # 执行恢复
        docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p"$MYSQL_PASSWORD" < "$backup_file"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 数据库恢复成功${NC}"
        else
            echo -e "${RED}❌ 数据库恢复失败${NC}"
        fi
    else
        echo -e "${YELLOW}❌ 操作已取消${NC}"
    fi
}

# 主函数
main() {
    case "${1:-}" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        clean)
            clean_services
            ;;
        backup)
            backup_database
            ;;
        restore)
            restore_database
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 