<template>
  <div class="profile-page">
    <el-card>
      <template #header>
        <span>个人信息</span>
      </template>

      <el-form
        ref="profileFormRef"
        :model="profileForm"
        :rules="profileRules"
        label-width="100px"
        style="max-width: 500px"
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="profileForm.username" placeholder="请输入用户名" />
        </el-form-item>

        <el-form-item label="邮箱" prop="email">
          <el-input v-model="profileForm.email" placeholder="请输入邮箱" />
        </el-form-item>

        <el-form-item label="新密码" prop="password">
          <el-input
            v-model="profileForm.password"
            type="password"
            placeholder="留空则不修改密码"
            show-password
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="loading">
            保存修改
          </el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import { ElMessage, type FormInstance, type FormRules } from "element-plus";
import { authApi } from "@/api";
import { useAuthStore } from "@/stores/auth";

const authStore = useAuthStore();
const profileFormRef = ref<FormInstance>();
const loading = ref(false);

const profileForm = reactive({
  username: "",
  email: "",
  password: "",
});

const profileRules: FormRules = {
  username: [
    { required: true, message: "请输入用户名", trigger: "blur" },
    { min: 2, max: 20, message: "长度在 2 到 20 个字符", trigger: "blur" },
  ],
  email: [
    { required: true, message: "请输入邮箱", trigger: "blur" },
    { type: "email", message: "请输入正确的邮箱格式", trigger: "blur" },
  ],
  password: [{ min: 6, message: "密码长度不能少于6位", trigger: "blur" }],
};

// 加载个人信息
const loadProfile = async () => {
  try {
    const response = await authApi.getProfile();
    const user = response.data;

    profileForm.username = user.username;
    profileForm.email = user.email;
    profileForm.password = "";
  } catch (error: any) {
    ElMessage.error(error.message || "加载个人信息失败");
  }
};

// 提交表单
const handleSubmit = async () => {
  if (!profileFormRef.value) return;

  await profileFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true;

      try {
        const updateData: any = {
          username: profileForm.username,
          email: profileForm.email,
        };

        // 只有当密码不为空时才包含密码
        if (profileForm.password) {
          updateData.password = profileForm.password;
        }

        await authApi.updateProfile(updateData);
        ElMessage.success("个人信息更新成功");

        // 更新store中的用户信息
        await authStore.getProfile();

        // 清空密码字段
        profileForm.password = "";
      } catch (error: any) {
        ElMessage.error(error.message || "更新失败");
      } finally {
        loading.value = false;
      }
    }
  });
};

// 重置表单
const handleReset = () => {
  if (profileFormRef.value) {
    profileFormRef.value.resetFields();
  }
  loadProfile();
};

onMounted(() => {
  loadProfile();
});
</script>

<style scoped>
.profile-page {
  padding: 20px;
}
</style>
