# Vue Admin Frontend

基于 Vue 3 + TypeScript + Element Plus 的现代化管理后台前端项目。

## 技术栈

- 🎯 **Vue 3** - 渐进式 JavaScript 框架
- 🔧 **TypeScript** - 类型安全的 JavaScript
- 🎨 **Element Plus** - Vue 3 组件库
- 🚀 **Vite** - 下一代前端构建工具
- 📱 **Vue Router** - Vue.js 官方路由管理器
- 🗃️ **Pinia** - Vue 的状态管理库
- 🎯 **ESLint** - 代码质量检查工具
- 💅 **Prettier** - 代码格式化工具

## 功能特性

- 🎨 现代化 UI 设计
- 📱 响应式布局
- 🔐 用户认证系统
- 👥 用户管理功能
- 📊 数据可视化仪表盘
- 🔍 搜索和筛选功能
- 📄 分页组件
- 🎯 表单验证

## 快速开始

### 环境要求

- Node.js 18+
- npm 或 yarn

### 安装依赖

```bash
npm install
```

### 开发模式

```bash
npm run dev
```

应用将在 `http://localhost:3000` 启动

### 构建生产版本

```bash
npm run build
```

### 预览生产版本

```bash
npm run preview
```

## 项目结构

```
vue-admin/
├── src/
│   ├── components/     # 公共组件
│   ├── views/         # 页面组件
│   ├── router/        # 路由配置
│   ├── stores/        # 状态管理
│   ├── api/           # API 接口
│   ├── utils/         # 工具函数
│   ├── assets/        # 静态资源
│   ├── App.vue        # 根组件
│   └── main.ts        # 入口文件
├── public/            # 公共资源
├── package.json       # 项目配置
├── vite.config.ts     # Vite 配置
├── tsconfig.json      # TypeScript 配置
└── README.md          # 项目说明
```

## 页面说明

### 登录页面
- 路径：`/login`
- 功能：用户登录认证
- 默认账号：admin / admin123

### 仪表盘
- 路径：`/dashboard`
- 功能：数据统计和系统概览

### 用户管理
- 路径：`/users`
- 功能：用户的增删改查操作

## API 配置

项目已配置代理，API 请求会自动转发到后端服务：

```typescript
// vite.config.ts
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8080',
      changeOrigin: true
    }
  }
}
```

## 开发指南

### 添加新页面

1. 在 `src/views/` 目录下创建页面组件
2. 在 `src/router/index.ts` 中添加路由配置
3. 在侧边栏菜单中添加对应的菜单项

### 添加新组件

1. 在 `src/components/` 目录下创建组件
2. 使用 TypeScript 定义组件 props 和 emits
3. 添加适当的样式和文档

### 状态管理

使用 Pinia 进行状态管理：

```typescript
// src/stores/user.ts
import { defineStore } from 'pinia'

export const useUserStore = defineStore('user', {
  state: () => ({
    user: null,
    token: null
  }),
  actions: {
    setUser(user: any) {
      this.user = user
    }
  }
})
```

## 部署

### 构建

```bash
npm run build
```

### 部署到服务器

将 `dist` 目录下的文件部署到 Web 服务器即可。

## 开发计划

- [ ] 权限管理系统
- [ ] 角色管理
- [ ] 菜单管理
- [ ] 系统设置
- [ ] 日志管理
- [ ] 文件上传
- [ ] 数据导出
- [ ] 主题切换 