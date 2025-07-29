<template>
  <div class="users-page">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" @click="handleAdd">
            <el-icon><Plus /></el-icon>
            新增用户
          </el-button>
        </div>
      </template>

      <!-- 搜索栏 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="用户名">
          <el-input
            v-model="searchForm.username"
            placeholder="请输入用户名"
            clearable
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSearch">搜索</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 用户表格 -->
      <el-table :data="userList" v-loading="loading" style="width: 100%">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag
              :type="scope.row.status === 'active' ? 'success' : 'danger'"
            >
              {{ scope.row.status === "active" ? "启用" : "禁用" }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="200">
          <template #default="scope">
            <el-button size="small" @click="handleEdit(scope.row)"
              >编辑</el-button
            >
            <el-button
              size="small"
              type="danger"
              @click="handleDelete(scope.row)"
              >删除</el-button
            >
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pagination.current"
          v-model:page-size="pagination.size"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 用户表单对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="500px"
      @close="handleDialogClose"
    >
      <el-form
        ref="userFormRef"
        :model="userForm"
        :rules="userRules"
        label-width="80px"
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="userForm.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="userForm.email" placeholder="请输入邮箱" />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="!userForm.id">
          <el-input
            v-model="userForm.password"
            type="password"
            placeholder="请输入密码"
            show-password
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="userForm.status" placeholder="请选择状态">
            <el-option label="启用" value="active" />
            <el-option label="禁用" value="inactive" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import {
  ElMessage,
  ElMessageBox,
  type FormInstance,
  type FormRules,
} from "element-plus";
import { userApi } from "@/api";

// 用户类型定义
interface UserItem {
  id: number;
  username: string;
  email: string;
  status: string;
  createTime: string;
}

// 搜索表单
const searchForm = reactive({
  username: "",
});

// 所有用户数据（用于搜索）
const allUsers = ref<UserItem[]>([]);
// 显示的用户列表（过滤后）
const userList = ref<UserItem[]>([]);

// 分页
const pagination = reactive({
  current: 1,
  size: 10,
  total: 0,
});

// 加载状态
const loading = ref(false);

// 对话框
const dialogVisible = ref(false);
const dialogTitle = ref("新增用户");
const userFormRef = ref<FormInstance>();

// 用户表单
const userForm = reactive({
  id: "",
  username: "",
  email: "",
  password: "",
  status: "active",
});

// 表单验证规则
const userRules: FormRules = {
  username: [
    { required: true, message: "请输入用户名", trigger: "blur" },
    { min: 2, max: 20, message: "长度在 2 到 20 个字符", trigger: "blur" },
  ],
  email: [
    { required: true, message: "请输入邮箱", trigger: "blur" },
    { type: "email", message: "请输入正确的邮箱格式", trigger: "blur" },
  ],
  password: [
    { required: true, message: "请输入密码", trigger: "blur" },
    { min: 6, message: "密码长度不能少于6位", trigger: "blur" },
  ],
  status: [{ required: true, message: "请选择状态", trigger: "change" }],
};

// 加载用户列表
const loadUsers = async () => {
  loading.value = true;
  try {
    const response = await userApi.getUsers();
    allUsers.value = response.data || [];
    userList.value = [...allUsers.value]; // 初始显示所有用户
    pagination.total = userList.value.length;
  } catch (error: any) {
    ElMessage.error(error.message || "加载用户列表失败");
  } finally {
    loading.value = false;
  }
};

// 过滤用户
const filterUsers = () => {
  let filtered = [...allUsers.value];

  // 按用户名搜索
  if (searchForm.username) {
    filtered = filtered.filter((user) => {
      return user.username
        .toLowerCase()
        .includes(searchForm.username.toLowerCase());
    });
  }

  userList.value = filtered;
  pagination.total = userList.value.length;
  pagination.current = 1; // 重置到第一页
};

// 搜索
const handleSearch = () => {
  // 前端搜索过滤
  filterUsers();
};

// 重置搜索
const handleReset = () => {
  searchForm.username = "";
  userList.value = [...allUsers.value]; // 显示所有用户
  pagination.total = userList.value.length;
  pagination.current = 1;
};

// 新增用户
const handleAdd = () => {
  dialogTitle.value = "新增用户";
  userForm.id = "";
  userForm.username = "";
  userForm.email = "";
  userForm.password = "";
  userForm.status = "active";
  dialogVisible.value = true;
};

// 编辑用户
const handleEdit = (row: any) => {
  dialogTitle.value = "编辑用户";
  userForm.id = row.id;
  userForm.username = row.username;
  userForm.email = row.email;
  userForm.password = "";
  userForm.status = row.status || "active";
  dialogVisible.value = true;
};

// 删除用户
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除用户 "${row.username}" 吗？`,
      "警告",
      {
        confirmButtonText: "确定",
        cancelButtonText: "取消",
        type: "warning",
      }
    );

    await userApi.deleteUser(row.id);
    ElMessage.success("删除成功");
    loadUsers();
  } catch (error: any) {
    if (error !== "cancel") {
      ElMessage.error(error.message || "删除失败");
    }
  }
};

// 提交表单
const handleSubmit = async () => {
  if (!userFormRef.value) return;

  await userFormRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (userForm.id) {
          // 更新用户
          await userApi.updateUser(userForm.id, {
            username: userForm.username,
            email: userForm.email,
            status: userForm.status,
          });
          ElMessage.success("更新成功");
        } else {
          // 创建用户
          await userApi.createUser({
            username: userForm.username,
            email: userForm.email,
            password: userForm.password,
            status: userForm.status,
          });
          ElMessage.success("创建成功");
        }

        dialogVisible.value = false;
        loadUsers();
      } catch (error: any) {
        ElMessage.error(error.message || "操作失败");
      }
    }
  });
};

// 关闭对话框
const handleDialogClose = () => {
  if (userFormRef.value) {
    userFormRef.value.resetFields();
  }
};

// 分页大小改变
const handleSizeChange = (size: number) => {
  pagination.size = size;
  loadUsers();
};

// 当前页改变
const handleCurrentChange = (current: number) => {
  pagination.current = current;
  loadUsers();
};

onMounted(() => {
  loadUsers();
});
</script>

<style scoped>
.users-page {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-form {
  margin-bottom: 20px;
}

.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: center;
}
</style>
