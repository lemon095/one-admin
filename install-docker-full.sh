#!/bin/bash

# 完整的Docker + Docker Compose V2 安装脚本
# 支持 Amazon Linux、Ubuntu、Debian、CentOS、RHEL

set -e

echo "🐳 开始安装Docker和Docker Compose V2..."

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    ID=$ID
else
    echo "无法检测操作系统"
    exit 1
fi

echo "检测到操作系统: $OS $VER (ID: $ID)"

# Amazon Linux 2023 安装Docker
install_docker_amazon_linux() {
    echo "📦 在Amazon Linux 2023上安装Docker..."
    
    # 更新系统
    echo "📦 更新系统包..."
    sudo yum update -y
    
    # 安装Docker
    echo "📦 安装Docker..."
    sudo yum install -y docker
    
    # 启动Docker服务
    echo "🚀 启动Docker服务..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 添加用户到docker组
    echo "👤 配置用户权限..."
    sudo usermod -aG docker $USER
    
    echo "✅ Docker安装完成"
}

# Ubuntu/Debian 安装Docker
install_docker_ubuntu_debian() {
    echo "📦 在Ubuntu/Debian上安装Docker..."
    
    # 更新系统
    echo "📦 更新系统包..."
    sudo apt update && sudo apt upgrade -y
    
    # 安装依赖
    echo "📦 安装依赖包..."
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加Docker GPG密钥
    echo "🔑 添加Docker GPG密钥..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "📋 添加Docker仓库..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    echo "📦 安装Docker..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # 启动Docker服务
    echo "🚀 启动Docker服务..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 添加用户到docker组
    echo "👤 配置用户权限..."
    sudo usermod -aG docker $USER
    
    echo "✅ Docker安装完成"
}

# CentOS/RHEL 安装Docker
install_docker_centos_rhel() {
    echo "📦 在CentOS/RHEL上安装Docker..."
    
    # 更新系统
    echo "📦 更新系统包..."
    sudo yum update -y
    
    # 安装依赖
    echo "📦 安装依赖包..."
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    
    # 添加Docker仓库
    echo "📋 添加Docker仓库..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # 安装Docker
    echo "📦 安装Docker..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    
    # 启动Docker服务
    echo "🚀 启动Docker服务..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 添加用户到docker组
    echo "👤 配置用户权限..."
    sudo usermod -aG docker $USER
    
    echo "✅ Docker安装完成"
}

# 检查Docker是否已安装
check_docker() {
    if command -v docker &> /dev/null; then
        echo "✅ Docker已安装: $(docker --version)"
        return 0
    else
        echo "❌ Docker未安装"
        return 1
    fi
}

# 安装Docker Compose V2
install_compose_v2() {
    echo "📦 安装Docker Compose V2..."
    
    # 创建插件目录
    sudo mkdir -p ~/.docker/cli-plugins/
    
    # 下载Docker Compose V2
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    echo "📥 下载Docker Compose V2版本: $COMPOSE_VERSION"
    
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o ~/.docker/cli-plugins/docker-compose
    
    # 添加执行权限
    sudo chmod +x ~/.docker/cli-plugins/docker-compose
    
    # 创建软链接到系统路径
    sudo ln -sf ~/.docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose V2安装完成"
}

# 配置Docker镜像加速（国内服务器）
configure_docker_mirrors() {
    echo "⚙️  配置Docker镜像加速..."
    
    # 创建配置目录
    sudo mkdir -p /etc/docker
    
    # 检查是否已有配置
    if [ -f /etc/docker/daemon.json ]; then
        echo "⚠️  Docker配置文件已存在，备份为 /etc/docker/daemon.json.bak"
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    fi
    
    # 创建配置文件
    sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    # 重启Docker服务
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    echo "✅ Docker镜像加速配置完成"
}

# 验证安装
verify_installation() {
    echo "🔍 验证安装..."
    
    # 验证Docker
    if docker --version &> /dev/null; then
        echo "✅ Docker安装成功："
        docker --version
    else
        echo "❌ Docker安装失败"
        return 1
    fi
    
    # 验证Docker Compose V2
    if docker compose version &> /dev/null; then
        echo "✅ Docker Compose V2安装成功："
        docker compose version
    else
        echo "❌ Docker Compose V2安装失败"
        return 1
    fi
    
    # 测试Docker运行
    echo "🔍 测试Docker运行..."
    sudo docker run hello-world
    
    echo ""
    echo "🎉 Docker和Docker Compose V2安装完成！"
    echo ""
    echo "📖 使用方法："
    echo "   docker --version              # 查看Docker版本"
    echo "   docker compose version        # 查看Compose版本"
    echo "   docker compose up -d          # 启动服务"
    echo ""
    echo "⚠️  重要提示："
    echo "   请重新登录或执行 'newgrp docker' 使权限生效"
    echo "   然后就可以不使用sudo运行docker命令了"
}

# 主安装流程
main() {
    echo "🚀 开始安装Docker和Docker Compose V2..."
    
    # 检查是否已安装Docker
    if check_docker; then
        echo "✅ Docker已安装，跳过Docker安装步骤"
    else
        # 根据操作系统安装Docker
        case $ID in
            "amzn"|"amazon")
                install_docker_amazon_linux
                ;;
            "ubuntu"|"debian")
                install_docker_ubuntu_debian
                ;;
            "centos"|"rhel"|"rocky"|"almalinux")
                install_docker_centos_rhel
                ;;
            *)
                echo "❌ 不支持的操作系统: $ID"
                echo "💡 请手动安装Docker后重新运行此脚本"
                exit 1
                ;;
        esac
    fi
    
    # 安装Docker Compose V2
    install_compose_v2
    
    # 配置镜像加速（可选）
    read -p "是否配置Docker镜像加速？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_docker_mirrors
    fi
    
    # 验证安装
    verify_installation
}

# 显示帮助信息
show_help() {
    echo "Docker + Docker Compose V2 完整安装脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -m, --mirrors  自动配置镜像加速"
    echo ""
    echo "支持的操作系统："
    echo "  - Amazon Linux 2023"
    echo "  - Ubuntu/Debian"
    echo "  - CentOS/RHEL/Rocky/AlmaLinux"
}

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -m|--mirrors)
        echo "📦 自动配置镜像加速..."
        main
        configure_docker_mirrors
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