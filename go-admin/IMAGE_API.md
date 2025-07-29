# 图片上传管理 API 文档

## 功能概述

图片上传管理系统提供以下功能：

- 图片上传（支持设置过期时间）
- 图片信息查询
- 图片删除
- 自动过期清理
- 容器重启后图片不丢失

## API 接口

### 1. 上传图片

**接口地址：** `POST /api/v1/images/upload`

**请求方式：** `multipart/form-data`

**请求参数：**

- `image`: 图片文件（支持 jpg, jpeg, png, gif，最大 10MB）
- `expire_days`: 过期天数（1-365 天）

**请求示例：**

```bash
curl -X POST http://localhost:8081/api/v1/images/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/image.jpg" \
  -F "expire_days=30"
```

**响应示例：**

```json
{
  "code": 200,
  "message": "图片上传成功",
  "data": {
    "id": 1,
    "image_code": "a1b2c3d4",
    "file_name": "image.jpg",
    "file_path": "./uploads/images/a1b2c3d4.jpg",
    "file_size": 1024000,
    "file_type": "jpg",
    "upload_time": "2025-01-27T15:30:45Z",
    "expire_time": "2025-02-26T15:30:45Z",
    "status": "active",
    "remaining_time": 2592000000000000,
    "is_expired": false,
    "created_at": "2025-01-27T15:30:45Z",
    "updated_at": "2025-01-27T15:30:45Z"
  }
}
```

### 2. 获取图片列表

**接口地址：** `GET /api/v1/images`

**请求参数：**

- `page`: 页码（默认 1）
- `page_size`: 每页数量（默认 10，最大 100）

**请求示例：**

```bash
curl -X GET "http://localhost:8081/api/v1/images?page=1&page_size=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**响应示例：**

```json
{
  "code": 200,
  "message": "获取图片列表成功",
  "data": {
    "total": 5,
    "items": [
      {
        "id": 1,
        "image_code": "a1b2c3d4",
        "file_name": "image.jpg",
        "file_path": "./uploads/images/a1b2c3d4.jpg",
        "file_size": 1024000,
        "file_type": "jpg",
        "upload_time": "2025-01-27T15:30:45Z",
        "expire_time": "2025-02-26T15:30:45Z",
        "status": "active",
        "remaining_time": 2592000000000000,
        "is_expired": false,
        "created_at": "2025-01-27T15:30:45Z",
        "updated_at": "2025-01-27T15:30:45Z"
      }
    ]
  }
}
```

### 3. 获取图片详情

**接口地址：** `GET /api/v1/images/:id`

**请求示例：**

```bash
curl -X GET http://localhost:8081/api/v1/images/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. 根据图片码获取图片信息

**接口地址：** `GET /api/v1/images/code/:code`

**请求示例：**

```bash
curl -X GET http://localhost:8081/api/v1/images/code/a1b2c3d4
```

### 5. 访问图片文件

**接口地址：** `GET /api/v1/images/file/:code`

**请求示例：**

```bash
curl -X GET http://localhost:8081/api/v1/images/file/a1b2c3d4
```

### 6. 删除图片

**接口地址：** `DELETE /api/v1/images/:id`

**请求示例：**

```bash
curl -X DELETE http://localhost:8081/api/v1/images/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 数据模型

### Image 模型

| 字段          | 类型      | 说明                           |
| ------------- | --------- | ------------------------------ |
| `id`          | int       | 主键 ID                        |
| `image_code`  | string    | 唯一图片码（8 位）             |
| `file_name`   | string    | 原始文件名                     |
| `file_path`   | string    | 存储路径                       |
| `file_size`   | int64     | 文件大小（字节）               |
| `file_type`   | string    | 文件类型                       |
| `upload_time` | time.Time | 上传时间                       |
| `expire_time` | time.Time | 过期时间                       |
| `status`      | string    | 状态（active/expired/deleted） |
| `created_at`  | time.Time | 创建时间                       |
| `updated_at`  | time.Time | 更新时间                       |

### ImageResponse 响应结构

| 字段             | 类型          | 说明         |
| ---------------- | ------------- | ------------ |
| `remaining_time` | time.Duration | 剩余有效时间 |
| `is_expired`     | bool          | 是否已过期   |

## 特性说明

### 1. 文件存储

- 图片存储在 `./uploads/images/` 目录
- 文件名使用唯一图片码命名
- 支持容器重启后数据持久化

### 2. 自动过期

- 每小时自动检查过期图片
- 过期图片状态更新为 "expired"
- 过期图片文件自动删除

### 3. 安全验证

- 支持的文件类型：jpg, jpeg, png, gif
- 最大文件大小：10MB
- 过期天数限制：1-365 天

### 4. 唯一标识

- 自动生成 8 位唯一图片码
- 基于 UUID 生成，确保唯一性

## 错误码说明

| 错误码 | 说明           |
| ------ | -------------- |
| 400    | 请求参数错误   |
| 401    | 未授权访问     |
| 404    | 图片不存在     |
| 500    | 服务器内部错误 |

## 使用示例

### 前端上传示例（JavaScript）

```javascript
const formData = new FormData();
formData.append("image", fileInput.files[0]);
formData.append("expire_days", "30");

fetch("/api/v1/images/upload", {
  method: "POST",
  headers: {
    Authorization: "Bearer " + token,
  },
  body: formData,
})
  .then((response) => response.json())
  .then((data) => {
    console.log("上传成功:", data);
  });
```

### 显示图片示例

```html
<!-- 直接访问图片 -->
<img src="/api/v1/images/file/a1b2c3d4" alt="图片" />

<!-- 或者使用图片码获取信息 -->
<script>
  fetch("/api/v1/images/code/a1b2c3d4")
    .then((response) => response.json())
    .then((data) => {
      if (!data.data.is_expired) {
        document.getElementById("image").src = "/api/v1/images/file/a1b2c3d4";
      }
    });
</script>
```
