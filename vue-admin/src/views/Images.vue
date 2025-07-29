<template>
  <div class="images-page">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>图片管理</h2>
      <el-button type="primary" @click="showUploadDialog = true">
        <el-icon><Upload /></el-icon>
        上传图片
      </el-button>
    </div>

    <!-- 搜索栏 -->
    <el-form :inline="true" :model="searchForm" class="search-form">
      <el-form-item label="图片码">
        <el-input
          v-model="searchForm.imageCode"
          placeholder="请输入图片码"
          clearable
        />
      </el-form-item>
      <el-form-item label="状态">
        <el-select
          v-model="searchForm.status"
          placeholder="请选择状态"
          clearable
        >
          <el-option label="有效" value="active" />
          <el-option label="已过期" value="expired" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleSearch">搜索</el-button>
        <el-button @click="handleReset">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- 图片列表 -->
    <el-table
      :data="imageList"
      v-loading="loading"
      style="width: 100%"
      :header-cell-style="{ background: '#f5f7fa' }"
    >
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="image_code" label="图片码" width="120" />
      <el-table-column label="预览" width="120">
        <template #default="{ row }">
          <el-image
            :src="`/api/v1/images/file/${row.image_code}`"
            :preview-src-list="[`/api/v1/images/file/${row.image_code}`]"
            fit="cover"
            style="width: 60px; height: 60px; border-radius: 4px"
            :initial-index="0"
          >
            <template #error>
              <div class="image-error">
                <el-icon><Picture /></el-icon>
              </div>
            </template>
          </el-image>
        </template>
      </el-table-column>
      <el-table-column prop="file_name" label="文件名" min-width="150" />
      <el-table-column prop="file_size" label="文件大小" width="100">
        <template #default="{ row }">
          {{ formatFileSize(row.file_size) }}
        </template>
      </el-table-column>
      <el-table-column prop="file_type" label="类型" width="80" />
      <el-table-column prop="upload_time" label="上传时间" width="180">
        <template #default="{ row }">
          {{ formatDateTime(row.upload_time) }}
        </template>
      </el-table-column>
      <el-table-column prop="expire_time" label="过期时间" width="180">
        <template #default="{ row }">
          {{ formatDateTime(row.expire_time) }}
        </template>
      </el-table-column>
      <el-table-column label="剩余时间" width="120">
        <template #default="{ row }">
          <el-tag :type="row.is_expired ? 'danger' : 'success'" size="small">
            {{
              row.is_expired
                ? "已过期"
                : formatRemainingTime(row.remaining_time)
            }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag
            :type="row.status === 'active' ? 'success' : 'danger'"
            size="small"
          >
            {{ row.status === "active" ? "有效" : "已过期" }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button type="primary" size="small" @click="handleView(row)">
            查看
          </el-button>
          <el-button type="danger" size="small" @click="handleDelete(row)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-container">
      <el-pagination
        v-model:current-page="pagination.current"
        v-model:page-size="pagination.pageSize"
        :page-sizes="[10, 20, 50, 100]"
        :total="pagination.total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 上传对话框 -->
    <el-dialog
      v-model="showUploadDialog"
      title="上传图片"
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form
        ref="uploadFormRef"
        :model="uploadForm"
        :rules="uploadRules"
        label-width="100px"
      >
        <el-form-item label="选择图片" prop="image">
          <el-upload
            ref="uploadRef"
            :auto-upload="false"
            :on-change="handleFileChange"
            :before-upload="beforeUpload"
            :limit="1"
            accept=".jpg,.jpeg,.png,.gif"
            drag
          >
            <el-icon class="el-icon--upload"><upload-filled /></el-icon>
            <div class="el-upload__text">
              将文件拖到此处，或<em>点击上传</em>
            </div>
            <template #tip>
              <div class="el-upload__tip">
                只能上传 jpg/png/gif 文件，且不超过 10MB
              </div>
            </template>
          </el-upload>
        </el-form-item>
        <el-form-item label="过期时间" prop="expire_value">
          <div style="display: flex; align-items: center; gap: 10px">
            <el-input-number
              v-model="uploadForm.expire_value"
              :min="1"
              :max="
                uploadForm.expire_unit === 'minutes'
                  ? 525600
                  : uploadForm.expire_unit === 'hours'
                    ? 8760
                    : 365
              "
              placeholder="请输入过期时间"
              style="width: 150px"
            />
            <el-select v-model="uploadForm.expire_unit" style="width: 100px">
              <el-option label="分钟" value="minutes" />
              <el-option label="小时" value="hours" />
              <el-option label="天" value="days" />
            </el-select>
          </div>
          <span class="form-tip">
            {{
              uploadForm.expire_unit === "minutes"
                ? "1-525600分钟"
                : uploadForm.expire_unit === "hours"
                  ? "1-8760小时"
                  : "1-365天"
            }}
          </span>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showUploadDialog = false">取消</el-button>
          <el-button type="primary" @click="handleUpload" :loading="uploading">
            上传
          </el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 查看详情对话框 -->
    <el-dialog v-model="showViewDialog" title="图片详情" width="600px">
      <div v-if="currentImage" class="image-detail">
        <div class="image-preview">
          <el-image
            :src="`/api/v1/images/file/${currentImage.image_code}`"
            fit="contain"
            style="width: 100%; max-height: 300px"
          />
        </div>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="图片码">{{
            currentImage.image_code
          }}</el-descriptions-item>
          <el-descriptions-item label="文件名">{{
            currentImage.file_name
          }}</el-descriptions-item>
          <el-descriptions-item label="文件大小">{{
            formatFileSize(currentImage.file_size)
          }}</el-descriptions-item>
          <el-descriptions-item label="文件类型">{{
            currentImage.file_type
          }}</el-descriptions-item>
          <el-descriptions-item label="上传时间">{{
            formatDateTime(currentImage.upload_time)
          }}</el-descriptions-item>
          <el-descriptions-item label="过期时间">{{
            formatDateTime(currentImage.expire_time)
          }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag
              :type="currentImage.status === 'active' ? 'success' : 'danger'"
            >
              {{ currentImage.status === "active" ? "有效" : "已过期" }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="剩余时间">
            {{
              currentImage.is_expired
                ? "已过期"
                : formatRemainingTime(currentImage.remaining_time)
            }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import {
  ElMessage,
  ElMessageBox,
  type FormInstance,
  type UploadInstance,
} from "element-plus";
import { Upload, UploadFilled, Picture } from "@element-plus/icons-vue";
import { imageApi } from "@/api";

// 图片类型定义
interface ImageItem {
  id: number;
  image_code: string;
  file_name: string;
  file_size: number;
  file_type: string;
  upload_time: string;
  expire_time: string;
  status: string;
  remaining_time: number;
  is_expired: boolean;
}

// 响应式数据
const loading = ref(false);
const uploading = ref(false);
const showUploadDialog = ref(false);
const showViewDialog = ref(false);
const currentImage = ref<ImageItem | null>(null);
const uploadFormRef = ref<FormInstance>();
const uploadRef = ref<UploadInstance>();

// 搜索表单
const searchForm = reactive({
  imageCode: "",
  status: "",
});

// 上传表单
const uploadForm = reactive({
  image: null as File | null,
  expire_value: 30,
  expire_unit: "days" as "minutes" | "hours" | "days",
});

// 上传验证规则
const uploadRules = {
  image: [{ required: true, message: "请选择图片文件", trigger: "change" }],
  expire_value: [
    { required: true, message: "请输入过期时间", trigger: "blur" },
    {
      type: "number",
      min: 1,
      message: "过期时间必须大于0",
      trigger: "blur",
    },
  ],
  expire_unit: [
    { required: true, message: "请选择时间单位", trigger: "change" },
  ],
};

// 分页
const pagination = reactive({
  current: 1,
  pageSize: 10,
  total: 0,
});

// 图片列表
const imageList = ref<ImageItem[]>([]);

// 加载图片列表
const loadImages = async () => {
  loading.value = true;
  try {
    const response = await imageApi.getImages({
      page: pagination.current,
      pageSize: pagination.pageSize,
    });
    imageList.value = response.data.items || [];
    pagination.total = response.data.total || 0;
  } catch (error: any) {
    ElMessage.error(error.message || "加载图片列表失败");
  } finally {
    loading.value = false;
  }
};

// 搜索
const handleSearch = () => {
  pagination.current = 1;
  loadImages();
};

// 重置搜索
const handleReset = () => {
  searchForm.imageCode = "";
  searchForm.status = "";
  pagination.current = 1;
  loadImages();
};

// 分页大小改变
const handleSizeChange = (size: number) => {
  pagination.pageSize = size;
  pagination.current = 1;
  loadImages();
};

// 当前页改变
const handleCurrentChange = (page: number) => {
  pagination.current = page;
  loadImages();
};

// 文件选择
const handleFileChange = (file: any) => {
  uploadForm.image = file.raw;
};

// 上传前验证
const beforeUpload = (file: File) => {
  const isValidType = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/gif",
  ].includes(file.type);
  const isLt10M = file.size / 1024 / 1024 < 10;

  if (!isValidType) {
    ElMessage.error("只能上传 JPG/PNG/GIF 格式的图片!");
    return false;
  }
  if (!isLt10M) {
    ElMessage.error("图片大小不能超过 10MB!");
    return false;
  }
  return false; // 阻止自动上传
};

// 上传图片
const handleUpload = async () => {
  if (!uploadFormRef.value) return;

  await uploadFormRef.value.validate(async (valid) => {
    if (valid && uploadForm.image) {
      uploading.value = true;
      try {
        const formData = new FormData();
        formData.append("image", uploadForm.image);
        formData.append("expire_value", uploadForm.expire_value.toString());
        formData.append("expire_unit", uploadForm.expire_unit);

        await imageApi.uploadImage(formData);
        ElMessage.success("图片上传成功");
        showUploadDialog.value = false;
        loadImages();

        // 重置表单
        uploadForm.image = null;
        uploadForm.expire_value = 30;
        uploadForm.expire_unit = "days";
        uploadRef.value?.clearFiles();
      } catch (error: any) {
        ElMessage.error(error.message || "上传失败");
      } finally {
        uploading.value = false;
      }
    }
  });
};

// 查看图片
const handleView = (row: any) => {
  currentImage.value = row;
  showViewDialog.value = true;
};

// 删除图片
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除图片 "${row.file_name}" 吗？`,
      "提示",
      {
        confirmButtonText: "确定",
        cancelButtonText: "取消",
        type: "warning",
      }
    );

    await imageApi.deleteImage(row.id);
    ElMessage.success("删除成功");
    loadImages();
  } catch (error: any) {
    if (error !== "cancel") {
      ElMessage.error(error.message || "删除失败");
    }
  }
};

// 格式化文件大小
const formatFileSize = (bytes: number) => {
  if (bytes === 0) return "0 B";
  const k = 1024;
  const sizes = ["B", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
};

// 格式化日期时间
const formatDateTime = (dateStr: string) => {
  return new Date(dateStr).toLocaleString("zh-CN");
};

// 格式化剩余时间
const formatRemainingTime = (duration: number) => {
  const days = Math.floor(duration / (1000 * 60 * 60 * 24));
  const hours = Math.floor(
    (duration % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
  );
  const minutes = Math.floor((duration % (1000 * 60 * 60)) / (1000 * 60));

  if (days > 0) {
    return `${days}天${hours}小时`;
  } else if (hours > 0) {
    return `${hours}小时${minutes}分钟`;
  } else {
    return `${minutes}分钟`;
  }
};

onMounted(() => {
  loadImages();
});
</script>

<style scoped>
.images-page {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  color: #303133;
}

.search-form {
  margin-bottom: 20px;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 4px;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: center;
}

.image-error {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 60px;
  height: 60px;
  background: #f5f7fa;
  color: #c0c4cc;
  border-radius: 4px;
}

.form-tip {
  margin-left: 10px;
  color: #909399;
  font-size: 12px;
}

.image-detail {
  .image-preview {
    margin-bottom: 20px;
    text-align: center;
  }
}

:deep(.el-upload-dragger) {
  width: 100%;
}

:deep(.el-upload__tip) {
  color: #909399;
  font-size: 12px;
  margin-top: 8px;
}
</style>
