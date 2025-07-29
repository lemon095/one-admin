#!/bin/bash

# Go Admin 生产环境管理脚本
# 支持 prod 和 dev 两种模式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
COMPOSE_PROD_FILE="$SCRIPT_DIR/docker-compose.prod.yml"
ENV_FILE="$SCRIPT_DIR/env.prod"

# 数据库配置
MYSQL_PASSWORD="shgytywe!#%65926328"
REDIS_PASSWORD="Test!#$1234.hjdgsag"
MYSQL_PORT="3306"
REDIS_PORT="6379"
MYSQL_CONTAINER_NAME="go-admin-mysql"
REDIS_CONTAINER_NAME="go-admin-redis"
NETWORK_NAME="go-admin-network"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Go Admin 生产环境管理脚本${NC}"
    echo ""
    echo "用法: $0 [环境] [命令]"
    echo ""
    echo "环境:"
    echo "  prod    生产环境 - 启动所有服务（Go + MySQL + Redis）"
    echo "  dev     开发环境 - 只启动Go服务（连接本地数据库）"
    echo ""
    echo "命令:"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  update    更新代码并重启"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  build     重新构建镜像"
    echo "  clean     清理容器和镜像"
    echo "  backup    备份数据库"
    echo "  restore   恢复数据库"
    echo "  stash     查看暂存的更改"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 prod start    # 生产环境启动所有服务"
    echo "  $0 dev start     # 开发环境启动Go服务"
    echo "  $0 prod status   # 查看生产环境状态"
    echo "  $0 dev logs      # 查看开发环境日志"
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

# 检查Docker Compose是否安装
check_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose未安装，请先安装Docker Compose${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker Compose已安装${NC}"
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
            --restart unless-stopped \
            mysql:8.0 \
            --default-authentication-plugin=mysql_native_password \
            --character-set-server=utf8mb4 \
            --collation-server=utf8mb4_unicode_ci \
            --default-time-zone='+8:00'
    fi
    
    echo -e "${GREEN}✅ MySQL服务启动成功${NC}"
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
            --restart unless-stopped \
            redis:7-alpine \
            redis-server --appendonly yes --requirepass "$REDIS_PASSWORD"
    fi
    
    echo -e "${GREEN}✅ Redis服务启动成功${NC}"
}

# 启动生产环境（只启动Go服务，连接现有数据库）
start_prod() {
    echo -e "${BLUE}🚀 启动生产环境（Go服务）...${NC}"
    
    check_docker
    check_compose
    
    # 检查数据库容器是否运行
    echo -e "${YELLOW}🔍 检查数据库服务状态...${NC}"
    
    # 检查MySQL容器（支持多种可能的容器名）
    MYSQL_RUNNING=false
    if docker ps --format "table {{.Names}}" | grep -q "mysql"; then
        MYSQL_CONTAINER=$(docker ps --format "table {{.Names}}" | grep "mysql" | head -1)
        echo -e "${GREEN}✅ 发现MySQL容器: $MYSQL_CONTAINER${NC}"
        MYSQL_RUNNING=true
    else
        echo -e "${RED}❌ 未发现运行中的MySQL容器${NC}"
        echo -e "${BLUE}💡 请确保MySQL容器正在运行${NC}"
        exit 1
    fi
    
    # 检查Redis容器（支持多种可能的容器名）
    REDIS_RUNNING=false
    if docker ps --format "table {{.Names}}" | grep -q "redis"; then
        REDIS_CONTAINER=$(docker ps --format "table {{.Names}}" | grep "redis" | head -1)
        echo -e "${GREEN}✅ 发现Redis容器: $REDIS_CONTAINER${NC}"
        REDIS_RUNNING=true
    else
        echo -e "${RED}❌ 未发现运行中的Redis容器${NC}"
        echo -e "${BLUE}💡 请确保Redis容器正在运行${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 数据库服务检查完成${NC}"
    
    # 清理未使用的镜像资源
    echo -e "${YELLOW}🧹 清理未使用的镜像资源...${NC}"
    docker system prune -f
    
    # 启动Go服务（生产环境profile）
    echo -e "${YELLOW}📦 构建并启动 Go Admin 服务...${NC}"
    docker-compose -f $COMPOSE_FILE --profile prod up --build -d
    
    echo -e "${GREEN}🎉 生产环境启动完成！${NC}"
    echo ""
    echo -e "${BLUE}📊 服务状态:${NC}"
    docker ps --filter "name=go-admin-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# 启动开发环境（只启动Go服务）
start_dev() {
    echo -e "${BLUE}🚀 启动开发环境（只启动Go服务）...${NC}"
    
    check_docker
    check_compose
    
    # 清理未使用的镜像资源
    echo -e "${YELLOW}🧹 清理未使用的镜像资源...${NC}"
    docker system prune -f
    
    # 启动Go服务（开发环境profile，连接本地数据库）
    echo -e "${YELLOW}📦 构建并启动 Go Admin 服务...${NC}"
    echo -e "${BLUE}💡 注意：Go服务将连接本地数据库${NC}"
    docker-compose -f $COMPOSE_FILE --profile dev up --build -d
    
         echo -e "${GREEN}🎉 开发环境启动完成！${NC}"
     echo ""
     echo -e "${BLUE}📊 服务状态:${NC}"
     docker ps --filter "name=go-admin-api-dev" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# 停止生产环境
stop_prod() {
    echo -e "${YELLOW}🛑 停止生产环境服务...${NC}"
    
    # 停止Go服务（生产环境profile）
    docker-compose -f $COMPOSE_FILE --profile prod down
    
    # 停止数据库服务
    if docker ps --format "table {{.Names}}" | grep -q $MYSQL_CONTAINER_NAME; then
        docker stop $MYSQL_CONTAINER_NAME
        echo -e "${GREEN}✅ MySQL服务已停止${NC}"
    fi
    
    if docker ps --format "table {{.Names}}" | grep -q $REDIS_CONTAINER_NAME; then
        docker stop $REDIS_CONTAINER_NAME
        echo -e "${GREEN}✅ Redis服务已停止${NC}"
    fi
}

# 停止开发环境
stop_dev() {
    echo -e "${YELLOW}🛑 停止开发环境服务...${NC}"
    docker-compose -f $COMPOSE_FILE --profile dev down
}

# 重启服务
restart_services() {
    local env=$1
    echo -e "${YELLOW}🔄 重启 $env 环境服务...${NC}"
    
    if [ "$env" = "prod" ]; then
        stop_prod
        sleep 2
        start_prod
    else
        stop_dev
        sleep 2
        start_dev
    fi
}

# 更新代码并重启
update_services() {
    local env=$1
    echo -e "${BLUE}🔄 更新 $env 环境服务...${NC}"
    
    check_docker
    check_compose
    
    # 检查并处理 Git 仓库
    if [ -d ".git" ]; then
        echo -e "${YELLOW}🔍 检查 Git 仓库状态...${NC}"
        
        # 获取当前分支
        CURRENT_BRANCH=$(git branch --show-current)
        echo -e "${BLUE}📋 当前分支: $CURRENT_BRANCH${NC}"
        
        # 检查是否有未提交的更改
        if ! git diff-index --quiet HEAD --; then
            echo -e "${YELLOW}📝 检测到未提交的更改，正在暂存...${NC}"
            
            # 获取当前时间戳作为暂存消息
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            STASH_MESSAGE="Auto stash before update - $TIMESTAMP"
            
            # 暂存更改
            git stash push -m "$STASH_MESSAGE"
            echo -e "${GREEN}✅ 更改已暂存: $STASH_MESSAGE${NC}"
        else
            echo -e "${GREEN}✅ 工作目录干净，无需暂存${NC}"
        fi
        
        # 拉取远程分支
        echo -e "${YELLOW}📥 拉取远程分支...${NC}"
        if git pull origin $CURRENT_BRANCH; then
            echo -e "${GREEN}✅ 代码更新成功${NC}"
        else
            echo -e "${RED}❌ 代码拉取失败，继续使用当前版本${NC}"
        fi
        
        # 如果有暂存的更改，提示用户
        if git stash list | grep -q "$STASH_MESSAGE"; then
            echo -e "${YELLOW}💡 提示: 有暂存的更改，可以使用以下命令恢复:${NC}"
            echo -e "${BLUE}   git stash pop${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  不在 Git 仓库中，跳过代码更新${NC}"
    fi
    
    # 停止服务
    if [ "$env" = "prod" ]; then
        stop_prod
    else
        stop_dev
    fi
    
    # 清理未使用的镜像资源
    echo -e "${YELLOW}🧹 清理未使用的镜像资源...${NC}"
    docker system prune -f
    
    # 重新构建并启动
    if [ "$env" = "prod" ]; then
        start_prod
    else
        start_dev
    fi
}

# 查看服务状态
show_status() {
    local env=$1
    echo -e "${BLUE}📊 $env 环境服务状态:${NC}"
    echo ""
    
         if [ "$env" = "prod" ]; then
         # 生产环境状态
         if docker ps --format "table {{.Names}}" | grep -q go-admin-api; then
             echo -e "${GREEN}✅ Go Admin: 运行中${NC}"
         else
             echo -e "${RED}❌ Go Admin: 未运行${NC}"
         fi
         
         if docker ps --format "table {{.Names}}" | grep -q $MYSQL_CONTAINER_NAME; then
             echo -e "${GREEN}✅ MySQL: 运行中${NC}"
         else
             echo -e "${RED}❌ MySQL: 未运行${NC}"
         fi
         
         if docker ps --format "table {{.Names}}" | grep -q $REDIS_CONTAINER_NAME; then
             echo -e "${GREEN}✅ Redis: 运行中${NC}"
         else
             echo -e "${RED}❌ Redis: 未运行${NC}"
         fi
     else
         # 开发环境状态
         if docker ps --format "table {{.Names}}" | grep -q go-admin-api-dev; then
             echo -e "${GREEN}✅ Go Admin: 运行中${NC}"
         else
             echo -e "${RED}❌ Go Admin: 未运行${NC}"
         fi
     fi
    
    echo ""
    echo -e "${BLUE}🔗 连接信息:${NC}"
    if [ "$env" = "prod" ]; then
        echo -e "   Go Admin: http://localhost:8081"
        echo -e "   MySQL: localhost:$MYSQL_PORT (root/$MYSQL_PASSWORD)"
        echo -e "   Redis: localhost:$REDIS_PORT (密码: $REDIS_PASSWORD)"
    else
        echo -e "   Go Admin: http://localhost:8081"
        echo -e "   MySQL: 本地数据库"
        echo -e "   Redis: 本地Redis"
    fi
}

# 查看服务日志
show_logs() {
    local env=$1
    echo -e "${BLUE}📋 选择要查看的日志:${NC}"
    
    if [ "$env" = "prod" ]; then
        echo "1) Go Admin 日志"
        echo "2) MySQL 日志"
        echo "3) Redis 日志"
        echo "4) 所有日志"
        read -p "请选择 (1-4): " choice
        
                 case $choice in
             1)
                 echo -e "${YELLOW}📋 Go Admin 日志:${NC}"
                 docker-compose -f $COMPOSE_FILE --profile prod logs -f go-admin
                 ;;
             2)
                 echo -e "${YELLOW}📋 MySQL 日志:${NC}"
                 docker logs -f $MYSQL_CONTAINER_NAME
                 ;;
             3)
                 echo -e "${YELLOW}📋 Redis 日志:${NC}"
                 docker logs -f $REDIS_CONTAINER_NAME
                 ;;
             4)
                 echo -e "${YELLOW}📋 所有服务日志:${NC}"
                 docker-compose -f $COMPOSE_FILE --profile prod logs -f
                 docker logs -f $MYSQL_CONTAINER_NAME &
                 docker logs -f $REDIS_CONTAINER_NAME &
                 wait
                 ;;
            *)
                echo -e "${RED}❌ 无效选择${NC}"
                ;;
        esac
    else
        echo "1) Go Admin 日志"
        echo "2) 所有日志"
        read -p "请选择 (1-2): " choice
        
                 case $choice in
             1)
                 echo -e "${YELLOW}📋 Go Admin 日志:${NC}"
                 docker-compose -f $COMPOSE_FILE --profile dev logs -f go-admin-dev
                 ;;
             2)
                 echo -e "${YELLOW}📋 所有日志:${NC}"
                 docker-compose -f $COMPOSE_FILE --profile dev logs -f
                 ;;
            *)
                echo -e "${RED}❌ 无效选择${NC}"
                ;;
        esac
    fi
}

# 重新构建镜像
build_images() {
    local env=$1
    echo -e "${BLUE}🔨 重新构建 $env 环境镜像...${NC}"
    
    check_docker
    check_compose
    
    if [ "$env" = "prod" ]; then
        docker-compose -f $COMPOSE_FILE --profile prod build --no-cache
    else
        docker-compose -f $COMPOSE_FILE --profile dev build --no-cache
    fi
    
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 清理容器和镜像
clean_services() {
    local env=$1
    echo -e "${RED}⚠️  危险操作！这将删除所有容器和镜像！${NC}"
    read -p "确定要继续吗？(输入 'yes' 确认): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}🧹 清理 $env 环境容器和镜像...${NC}"
        
        # 停止并删除容器
        if [ "$env" = "prod" ]; then
            docker-compose -f $COMPOSE_FILE --profile prod down --rmi all --volumes --remove-orphans
        else
            docker-compose -f $COMPOSE_FILE --profile dev down --rmi all --volumes --remove-orphans
        fi
        
        if [ "$env" = "prod" ]; then
            docker stop $MYSQL_CONTAINER_NAME $REDIS_CONTAINER_NAME 2>/dev/null || true
            docker rm $MYSQL_CONTAINER_NAME $REDIS_CONTAINER_NAME 2>/dev/null || true
            docker network rm $NETWORK_NAME 2>/dev/null || true
            docker volume rm mysql_data redis_data 2>/dev/null || true
        fi
        
        # 清理未使用的镜像
        docker system prune -a -f
        
        echo -e "${GREEN}✅ 清理完成${NC}"
    else
        echo -e "${YELLOW}❌ 操作已取消${NC}"
    fi
}

# 备份数据库
backup_database() {
    local env=$1
    echo -e "${BLUE}💾 备份数据库...${NC}"
    
    if [ "$env" = "prod" ]; then
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
    else
        echo -e "${YELLOW}⚠️  开发环境请手动备份本地数据库${NC}"
    fi
}

# 恢复数据库
restore_database() {
    local env=$1
    echo -e "${BLUE}📥 恢复数据库...${NC}"
    
    if [ "$env" = "prod" ]; then
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
    else
        echo -e "${YELLOW}⚠️  开发环境请手动恢复本地数据库${NC}"
    fi
}

# 查看暂存的更改
show_stash() {
    echo -e "${BLUE}📦 查看暂存的更改...${NC}"
    
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}⚠️  不在 Git 仓库中${NC}"
        return
    fi
    
    # 检查是否有暂存
    if git stash list | grep -q "Auto stash before update"; then
        echo -e "${YELLOW}📝 找到自动暂存的更改:${NC}"
        git stash list | grep "Auto stash before update"
        echo ""
        echo -e "${BLUE}💡 可以使用以下命令恢复暂存:${NC}"
        echo -e "${GREEN}   git stash pop${NC}"
        echo -e "${GREEN}   git stash apply stash@{0}${NC}"
        echo ""
        echo -e "${BLUE}💡 查看暂存内容:${NC}"
        echo -e "${GREEN}   git stash show -p stash@{0}${NC}"
    else
        echo -e "${GREEN}✅ 没有找到自动暂存的更改${NC}"
    fi
    
    # 显示所有暂存
    if git stash list | grep -q .; then
        echo ""
        echo -e "${BLUE}📋 所有暂存列表:${NC}"
        git stash list
    else
        echo -e "${GREEN}✅ 没有暂存的更改${NC}"
    fi
}

# 主函数
main() {
    local env="${1:-}"
    local command="${2:-}"
    
    case "$env" in
        prod|dev)
            case "$command" in
                start)
                    if [ "$env" = "prod" ]; then
                        start_prod
                    else
                        start_dev
                    fi
                    ;;
                stop)
                    if [ "$env" = "prod" ]; then
                        stop_prod
                    else
                        stop_dev
                    fi
                    ;;
                restart)
                    restart_services "$env"
                    ;;
                update)
                    update_services "$env"
                    ;;
                status)
                    show_status "$env"
                    ;;
                logs)
                    show_logs "$env"
                    ;;
                build)
                    build_images "$env"
                    ;;
                clean)
                    clean_services "$env"
                    ;;
                backup)
                    backup_database "$env"
                    ;;
                restore)
                    restore_database "$env"
                    ;;
                stash)
                    show_stash
                    ;;
                help|--help|-h)
                    show_help
                    ;;
                "")
                    show_help
                    ;;
                *)
                    echo -e "${RED}❌ 未知命令: $command${NC}"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知环境: $env${NC}"
            echo -e "${YELLOW}支持的环境: prod, dev${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 