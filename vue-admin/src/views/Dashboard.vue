<template>
  <div class="dashboard">
    <el-card class="welcome-card">
      <div class="welcome-content">
        <div class="welcome-icon">
          <el-icon size="60" color="#409EFF"><Sunny /></el-icon>
        </div>
        <div class="welcome-text">
          <h1>欢迎登录管理系统</h1>
          <p class="current-time">{{ currentTime }}</p>
          <p class="welcome-message">祝您工作愉快！</p>
        </div>
      </div>
    </el-card>

    <el-row :gutter="20" style="margin-top: 20px">
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>系统信息</span>
          </template>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="系统版本"
              >Vue Admin v1.0.0</el-descriptions-item
            >
            <el-descriptions-item label="Node版本"
              >v20.17.0</el-descriptions-item
            >
            <el-descriptions-item label="Vue版本">v3.4.0</el-descriptions-item>
            <el-descriptions-item label="Element Plus"
              >v2.4.0</el-descriptions-item
            >
          </el-descriptions>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <span>快速操作</span>
          </template>
          <div class="quick-actions">
            <el-button type="primary" @click="$router.push('/users')">
              <el-icon><User /></el-icon>
              用户管理
            </el-button>
            <el-button type="warning" @click="$router.push('/images')">
              <el-icon><Picture /></el-icon>
              图片管理
            </el-button>
            <el-button type="success" @click="$router.push('/profile')">
              <el-icon><Setting /></el-icon>
              个人信息
            </el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from "vue";
import { Sunny, User, Setting, Picture } from "@element-plus/icons-vue";

const currentTime = ref("");
let timer: number | null = null;

// 更新当前时间
const updateTime = () => {
  const now = new Date();
  currentTime.value = now.toLocaleString("zh-CN", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
};

onMounted(() => {
  updateTime();
  // 每秒更新一次时间
  timer = setInterval(updateTime, 1000);
});

onUnmounted(() => {
  if (timer) {
    clearInterval(timer);
  }
});
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.welcome-card {
  margin-bottom: 20px;
}

.welcome-content {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  text-align: center;
}

.welcome-icon {
  margin-right: 30px;
}

.welcome-text h1 {
  font-size: 32px;
  color: #303133;
  margin: 0 0 10px 0;
  font-weight: 600;
}

.current-time {
  font-size: 18px;
  color: #409eff;
  margin: 10px 0;
  font-weight: 500;
}

.welcome-message {
  font-size: 16px;
  color: #909399;
  margin: 10px 0 0 0;
}

.quick-actions {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
}

.quick-actions .el-button {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 12px 20px;
}
</style>
