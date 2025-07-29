#!/bin/bash

# 生产环境管理脚本
# 使用方法: ./prod.sh [start|stop|restart|logs|status|update|update-zero-downtime]

COMPOSE_FILE="docker-compose.yml"
SERVICE_NAME="go-admin-api"

case "$1" in
    start)
        echo "🚀 启动Go Admin服务..."
        docker-compose -f $COMPOSE_FILE up -d
        echo "✅ 启动完成！访问地址: http://localhost:8081"
        echo "💡 请确保MySQL和Redis容器已启动并可访问"
        ;;
    stop)
        echo "🛑 停止Go Admin服务..."
        docker-compose -f $COMPOSE_FILE down
        echo "✅ 停止完成！"
        ;;
    restart)
        echo "🔄 重启Go Admin服务..."
        docker-compose -f $COMPOSE_FILE down
        docker-compose -f $COMPOSE_FILE up -d
        echo "✅ 重启完成！"
        ;;
    logs)
        echo "📊 查看服务日志..."
        docker-compose -f $COMPOSE_FILE logs -f
        ;;
    status)
        echo "🔍 查看服务状态..."
        docker-compose -f $COMPOSE_FILE ps
        echo ""
        echo "📊 容器资源使用情况:"
        docker stats --no-stream
        ;;
    update)
        echo "🔄 更新并重启服务..."
        # 停止服务
        docker-compose -f $COMPOSE_FILE down
        
        # 强制删除可能存在的容器
        echo "🗑️  清理旧容器..."
        docker rm -f go-admin-api 2>/dev/null || true
        
        # 清理Docker资源
        echo "🗑️  清理未使用的Docker资源..."
        echo "y" | docker system prune
        
        # 启动服务（强制重新构建）
        echo "📦 启动服务..."
        docker-compose -f $COMPOSE_FILE up -d --build
        
        # 清理构建缓存
        echo "🗑️  清理构建缓存..."
        echo "y" | docker builder prune
        
        echo "✅ 更新完成！"
        ;;
    update-zero-downtime)
        echo "🚀 开始无痕更新服务..."
        
        # 检查当前服务状态
        if ! docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
            echo "❌ 当前没有运行的服务，无法进行无痕更新"
            echo "💡 请先运行: ./prod.sh start"
            exit 1
        fi
        
        echo "📦 构建新镜像..."
        docker-compose -f "$COMPOSE_FILE" up -d --build
        
        echo "🔄 执行无痕更新..."
        docker-compose -f $COMPOSE_FILE up -d --force-recreate
        
        # 等待新容器启动
        echo "⏳ 等待新容器启动..."
        sleep 10
        
        # 检查服务健康状态
        echo "🔍 检查服务健康状态..."
        for i in {1..30}; do
            if curl -f http://localhost:8081/health > /dev/null 2>&1; then
                echo "✅ 服务健康检查通过！"
                break
            fi
            echo "⏳ 等待服务启动... ($i/30)"
            sleep 2
        done
        
        # 清理旧镜像
        echo "🧹 清理旧镜像..."
        echo "y" | docker image prune
        
        echo "✅ 无痕更新完成！"
        echo "📊 当前服务状态:"
        docker-compose -f $COMPOSE_FILE ps
        ;;
    backup)
        echo "💾 备份数据库..."
        echo "⚠️  请手动备份您的MySQL容器数据"
        echo "💡 示例命令: docker exec mysql57 mysqldump -u root -pshgytywe!#%65926328 go_admin > backup_$(date +%Y%m%d_%H%M%S).sql"
        ;;
    clean)
        echo "🧹 清理未使用的Docker资源..."
        echo "y" | docker system prune
        echo "y" | docker volume prune
        echo "✅ 清理完成！"
        ;;
    *)
        echo "❓ 使用方法: $0 {start|stop|restart|logs|status|update|update-zero-downtime|backup|clean}"
        echo ""
        echo "命令说明:"
        echo "  start              - 启动Go Admin服务"
        echo "  stop               - 停止Go Admin服务"
        echo "  restart            - 重启Go Admin服务"
        echo "  logs               - 查看服务日志"
        echo "  status             - 查看服务状态"
        echo "  update             - 更新并重启服务（会短暂中断）"
        echo "  update-zero-downtime - 无痕更新服务（推荐）"
        echo "  backup             - 数据库备份提示"
        echo "  clean              - 清理Docker资源"
        echo ""
        echo "📝 配置说明:"
        echo "  - 后端API端口: 8081"
        echo "  - MySQL连接: mysql57:3306"
        echo "  - Redis连接: redis:6379"
        echo "  - MySQL密码: shgytywe!#%65926328"
        echo "  - Redis密码: Test!#\$1234.hjdgsag"
        echo ""
        echo "⚠️  注意: 请确保MySQL和Redis容器已启动并可访问"
        echo "🔍 网络检查: 确保MySQL和Redis容器在db-network网络中"
        echo ""
        echo "💡 更新建议: 使用 update-zero-downtime 进行无痕更新"
        exit 1
        ;;
esac 