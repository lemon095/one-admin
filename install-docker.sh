#!/bin/bash

# Docker一键安装脚本
# 支持 Ubuntu/Debian 和 CentOS/RHEL

set -e

echo "🐳 开始安装Docker环境..."

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

# Ubuntu/Debian安装
install_ubuntu_debian() {
    echo "📦 更新系统包..."
    sudo apt update && sudo apt upgrade -y
    
    echo "📦 安装依赖包..."
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    echo "🔑 添加Docker GPG密钥..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "📋 添加Docker仓库..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    echo "📦 安装Docker..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    echo "🚀 启动Docker服务..."
    sudo systemctl start docker
    sudo systemctl enable docker
}

# CentOS/RHEL安装
install_centos_rhel() {
    echo "📦 更新系统包..."
    sudo yum update -y
    
    echo "📦 安装依赖包..."
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    
    echo "🔑 添加Docker GPG密钥..."
    sudo rpm --import https://download.docker.com/linux/centos/gpg
    
    echo "📋 添加Docker仓库..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    echo "📦 安装Docker..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    
    echo "🚀 启动Docker服务..."
    sudo systemctl start docker
    sudo systemctl enable docker
}

# 安装Docker Compose V2
install_docker_compose() {
    echo "📦 安装Docker Compose V2..."
    
    # 方法1：通过Docker插件安装（推荐）
    if command -v docker &> /dev/null; then
        echo "📦 通过Docker插件安装Compose V2..."
        sudo mkdir -p ~/.docker/cli-plugins/
        sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o ~/.docker/cli-plugins/docker-compose
        sudo chmod +x ~/.docker/cli-plugins/docker-compose
        
        # 创建软链接到系统路径
        sudo ln -sf ~/.docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    else
        echo "📦 通过传统方式安装Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

# 配置用户权限
configure_permissions() {
    echo "👤 配置用户权限..."
    sudo usermod -aG docker $USER
    echo "✅ 已将用户 $USER 添加到docker组"
    echo "⚠️  请重新登录或执行 'newgrp docker' 使权限生效"
}

# 验证安装
verify_installation() {
    echo "🔍 验证Docker安装..."
    sudo docker --version
    
    echo "🔍 验证Docker Compose安装..."
    docker-compose --version
    
    echo "🔍 测试Docker运行..."
    sudo docker run hello-world
    
    echo "✅ Docker环境安装完成！"
}

# 主安装流程
main() {
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            install_ubuntu_debian
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            install_centos_rhel
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    install_docker_compose
    configure_permissions
    verify_installation
}

# 执行安装
main 