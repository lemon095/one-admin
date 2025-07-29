#!/bin/bash

# Docker Compose V2 安装脚本
# 支持 Ubuntu/Debian 和 CentOS/RHEL

set -e

echo "🐳 开始安装Docker Compose V2..."

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo "无法检测操作系统"
    exit 1
fi

echo "检测到操作系统: $OS $VER"

# 检查Docker是否已安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker未安装，请先安装Docker"
        echo "💡 可以使用以下命令安装Docker："
        echo "   curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    echo "✅ Docker已安装: $(docker --version)"
}

# 安装Docker Compose V2（推荐方式）
install_compose_v2_plugin() {
    echo "📦 安装Docker Compose V2（插件方式）..."
    
    # 创建插件目录
    sudo mkdir -p ~/.docker/cli-plugins/
    
    # 下载Docker Compose V2
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    echo "📥 下载Docker Compose V2版本: $COMPOSE_VERSION"
    
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o ~/.docker/cli-plugins/docker-compose
    
    # 添加执行权限
    sudo chmod +x ~/.docker/cli-plugins/docker-compose
    
    # 创建软链接到系统路径（可选）
    sudo ln -sf ~/.docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose V2安装完成"
}

# 安装Docker Compose V2（传统方式）
install_compose_v2_standalone() {
    echo "📦 安装Docker Compose V2（独立方式）..."
    
    # 下载最新版本
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    echo "📥 下载Docker Compose V2版本: $COMPOSE_VERSION"
    
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 添加执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose V2安装完成"
}

# 卸载旧版本docker-compose
uninstall_old_compose() {
    echo "🧹 检查并卸载旧版本docker-compose..."
    
    # 检查是否有旧版本
    if command -v docker-compose &> /dev/null; then
        OLD_VERSION=$(docker-compose --version)
        echo "发现旧版本: $OLD_VERSION"
        
        read -p "是否卸载旧版本？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 卸载通过包管理器安装的版本
            case $OS in
                *"Ubuntu"*|*"Debian"*)
                    sudo apt remove -y docker-compose 2>/dev/null || true
                    ;;
                *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
                    sudo yum remove -y docker-compose 2>/dev/null || true
                    ;;
            esac
            
            # 删除手动安装的版本
            sudo rm -f /usr/local/bin/docker-compose
            sudo rm -f /usr/bin/docker-compose
            
            echo "✅ 旧版本已卸载"
        fi
    fi
}

# 验证安装
verify_installation() {
    echo "🔍 验证Docker Compose V2安装..."
    
    # 检查插件版本
    if docker compose version &> /dev/null; then
        echo "✅ Docker Compose V2（插件方式）安装成功："
        docker compose version
    else
        echo "❌ Docker Compose V2（插件方式）安装失败"
        return 1
    fi
    
    # 检查独立版本
    if command -v docker-compose &> /dev/null; then
        echo "✅ Docker Compose V2（独立方式）安装成功："
        docker-compose --version
    fi
    
    echo ""
    echo "🎉 Docker Compose V2安装完成！"
    echo ""
    echo "📖 使用方法："
    echo "   docker compose up -d    # 推荐方式（V2）"
    echo "   docker-compose up -d    # 兼容方式"
    echo ""
    echo "📋 常用命令："
    echo "   docker compose ps       # 查看服务状态"
    echo "   docker compose logs     # 查看日志"
    echo "   docker compose down     # 停止服务"
    echo "   docker compose build    # 构建镜像"
}

# 配置Docker Compose
configure_compose() {
    echo "⚙️  配置Docker Compose..."
    
    # 创建配置文件目录
    mkdir -p ~/.docker
    
    # 创建配置文件（可选）
    if [ ! -f ~/.docker/config.json ]; then
        cat > ~/.docker/config.json << EOF
{
  "compose": {
    "version": "2"
  }
}
EOF
        echo "✅ 创建Docker配置文件"
    fi
}

# 主安装流程
main() {
    echo "🚀 开始安装Docker Compose V2..."
    
    # 检查Docker
    check_docker
    
    # 卸载旧版本
    uninstall_old_compose
    
    # 安装新版本（优先使用插件方式）
    install_compose_v2_plugin
    
    # 配置
    configure_compose
    
    # 验证
    verify_installation
}

# 显示帮助信息
show_help() {
    echo "Docker Compose V2 安装脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -s, --standalone 仅安装独立版本"
    echo ""
    echo "示例:"
    echo "  $0              # 安装Docker Compose V2"
    echo "  $0 --standalone # 仅安装独立版本"
}

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -s|--standalone)
        echo "📦 仅安装独立版本..."
        check_docker
        uninstall_old_compose
        install_compose_v2_standalone
        verify_installation
        ;;
    "")
        main
        ;;
    *)
        echo "❌ 未知选项: $1"
        show_help
        exit 1
        ;;
esac 