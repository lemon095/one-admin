#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="go-admin"
COMPOSE_FILE="docker-compose.yml"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Go Admin 生产环境管理脚本${NC}"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start    启动所有服务"
    echo "  stop     停止所有服务"
    echo "  restart  重启所有服务"
    echo "  update   更新代码并重启服务"
    echo "  status   查看服务状态"
    echo "  logs     查看服务日志"
    echo "  build    重新构建镜像"
    echo "  clean    清理容器和镜像"
    echo "  backup   备份数据库"
    echo "  restore  恢复数据库"
    echo "  stash    查看暂存的更改"
    echo "  help     显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start    # 启动服务"
    echo "  $0 stop     # 停止服务"
    echo "  $0 update   # 更新并重启"
    echo "  $0 stash    # 查看暂存"
    echo ""
}

# 检查 Docker 是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker 未运行，请先启动 Docker${NC}"
        exit 1
    fi
}

# 检查 docker-compose 是否可用
check_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ docker-compose 未安装${NC}"
        exit 1
    fi
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 启动 Go Admin 服务...${NC}"
    check_docker
    check_compose
    
    # 清理未使用的镜像资源
    echo -e "${YELLOW}🧹 清理未使用的镜像资源...${NC}"
    docker system prune -f
    
    echo -e "${YELLOW}📦 构建并启动 Docker 容器...${NC}"
    docker-compose -f $COMPOSE_FILE up --build -d
    
    echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
    sleep 15
    
    # 检查服务状态
    status_services
    
    echo -e "${GREEN}✅ 服务启动完成！${NC}"
    echo -e "${BLUE}📊 API 服务地址: http://localhost:8081${NC}"
    echo -e "${BLUE}🗄️  MySQL 地址: localhost:3306${NC}"
}

# 停止服务
stop_services() {
    echo -e "${YELLOW}🛑 停止 Go Admin 服务...${NC}"
    check_docker
    check_compose
    
    docker-compose -f $COMPOSE_FILE down
    
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 重启服务
restart_services() {
    echo -e "${YELLOW}🔄 重启 Go Admin 服务...${NC}"
    check_docker
    check_compose
    
    docker-compose -f $COMPOSE_FILE restart
    
    echo -e "${YELLOW}⏳ 等待服务重启...${NC}"
    sleep 10
    
    status_services
    echo -e "${GREEN}✅ 服务重启完成${NC}"
}

# 更新服务
update_services() {
    echo -e "${BLUE}🔄 更新 Go Admin 服务...${NC}"
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
    echo -e "${YELLOW}🛑 停止当前服务...${NC}"
    docker-compose -f $COMPOSE_FILE down
    
    # 清理未使用的镜像资源
    echo -e "${YELLOW}🧹 清理未使用的镜像资源...${NC}"
    docker system prune -f
    
    # 重新构建并启动
    echo -e "${YELLOW}🔨 重新构建镜像...${NC}"
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    echo -e "${YELLOW}🚀 启动更新后的服务...${NC}"
    docker-compose -f $COMPOSE_FILE up -d
    
    echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
    sleep 15
    
    status_services
    echo -e "${GREEN}✅ 服务更新完成${NC}"
}

# 查看服务状态
status_services() {
    echo -e "${BLUE}🔍 服务状态:${NC}"
    docker-compose -f $COMPOSE_FILE ps
    
    echo ""
    echo -e "${BLUE}📊 资源使用情况:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📝 查看服务日志 (按 Ctrl+C 退出)${NC}"
    docker-compose -f $COMPOSE_FILE logs -f
}

# 重新构建镜像
build_images() {
    echo -e "${BLUE}🔨 重新构建镜像...${NC}"
    check_docker
    check_compose
    
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    echo -e "${GREEN}✅ 镜像构建完成${NC}"
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}🧹 清理 Docker 资源...${NC}"
    check_docker
    
    # 停止并删除容器
    docker-compose -f $COMPOSE_FILE down -v
    
    # 删除相关镜像
    docker rmi $(docker images | grep go-admin | awk '{print $3}') 2>/dev/null || echo "没有找到相关镜像"
    
    # 清理未使用的资源
    docker system prune -f
    
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 备份数据库
backup_database() {
    echo -e "${BLUE}💾 备份数据库...${NC}"
    check_docker
    
    BACKUP_DIR="./backups"
    BACKUP_FILE="$BACKUP_DIR/go_admin_$(date +%Y%m%d_%H%M%S).sql"
    
    # 创建备份目录
    mkdir -p $BACKUP_DIR
    
    # 备份数据库
    docker-compose -f $COMPOSE_FILE exec -T mysql mysqldump -u root -proot go_admin > $BACKUP_FILE
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 数据库备份完成: $BACKUP_FILE${NC}"
    else
        echo -e "${RED}❌ 数据库备份失败${NC}"
        exit 1
    fi
}

# 恢复数据库
restore_database() {
    if [ -z "$1" ]; then
        echo -e "${RED}❌ 请指定备份文件路径${NC}"
        echo "用法: $0 restore <backup_file>"
        exit 1
    fi
    
    BACKUP_FILE=$1
    
    if [ ! -f "$BACKUP_FILE" ]; then
        echo -e "${RED}❌ 备份文件不存在: $BACKUP_FILE${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📥 恢复数据库...${NC}"
    check_docker
    
    # 恢复数据库
    docker-compose -f $COMPOSE_FILE exec -T mysql mysql -u root -proot go_admin < $BACKUP_FILE
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 数据库恢复完成${NC}"
    else
        echo -e "${RED}❌ 数据库恢复失败${NC}"
        exit 1
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
    case "$1" in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        update)
            update_services
            ;;
        status)
            status_services
            ;;
        logs)
            show_logs
            ;;
        build)
            build_images
            ;;
        clean)
            clean_resources
            ;;
        backup)
            backup_database
            ;;
        restore)
            restore_database $2
            ;;
        stash)
            show_stash
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@" 