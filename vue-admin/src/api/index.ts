import { useAuthStore } from "@/stores/auth";

// API基础URL
const API_BASE_URL = "/api/v1";

// 创建带认证的请求头
const createAuthHeaders = () => {
  const authStore = useAuthStore();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (authStore.token) {
    headers["Authorization"] = `Bearer ${authStore.token}`;
  }

  return headers;
};

// 通用API请求函数
export const apiRequest = async (
  endpoint: string,
  options: RequestInit = {}
): Promise<any> => {
  const authStore = useAuthStore();

  const config: RequestInit = {
    headers: createAuthHeaders(),
    ...options,
  };

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, config);

    // 如果返回401，说明token过期
    if (response.status === 401) {
      authStore.logout();
      throw new Error("Token已过期，请重新登录");
    }

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || `请求失败: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error("API request error:", error);
    throw error;
  }
};

// GET请求
export const apiGet = (endpoint: string) => {
  return apiRequest(endpoint, { method: "GET" });
};

// POST请求
export const apiPost = (endpoint: string, data: any) => {
  return apiRequest(endpoint, {
    method: "POST",
    body: JSON.stringify(data),
  });
};

// PUT请求
export const apiPut = (endpoint: string, data: any) => {
  return apiRequest(endpoint, {
    method: "PUT",
    body: JSON.stringify(data),
  });
};

// DELETE请求
export const apiDelete = (endpoint: string) => {
  return apiRequest(endpoint, { method: "DELETE" });
};

// 用户相关API
export const userApi = {
  // 获取用户列表
  getUsers: () => apiGet("/users"),

  // 获取单个用户
  getUser: (id: string) => apiGet(`/users/${id}`),

  // 创建用户
  createUser: (userData: any) => apiPost("/users", userData),

  // 更新用户
  updateUser: (id: string, userData: any) => apiPut(`/users/${id}`, userData),

  // 删除用户
  deleteUser: (id: string) => apiDelete(`/users/${id}`),

  // 获取当前用户信息
  getProfile: () => apiGet("/auth/profile"),
};

// 认证相关API
export const authApi = {
  // 登录
  login: (credentials: { username: string; password: string }) => {
    return fetch(`${API_BASE_URL}/auth/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(credentials),
    });
  },

  // 获取个人信息
  getProfile: () => apiGet("/auth/profile"),

  // 更新个人信息
  updateProfile: (data: {
    username?: string;
    email?: string;
    password?: string;
  }) => {
    return apiPut("/auth/profile", data);
  },
};

// 图片相关API
export const imageApi = {
  // 上传图片
  uploadImage: (formData: FormData) => {
    const authStore = useAuthStore();
    return fetch(`${API_BASE_URL}/images/upload`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${authStore.token}`,
      },
      body: formData,
    }).then(async (response) => {
      if (response.status === 401) {
        authStore.logout();
        throw new Error("Token已过期，请重新登录");
      }

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `请求失败: ${response.status}`);
      }

      return await response.json();
    });
  },

  // 获取图片列表
  getImages: (params: { page?: number; pageSize?: number }) => {
    const searchParams = new URLSearchParams();
    if (params.page) searchParams.append("page", params.page.toString());
    if (params.pageSize)
      searchParams.append("page_size", params.pageSize.toString());

    return apiGet(`/images?${searchParams.toString()}`);
  },

  // 获取图片详情
  getImage: (id: number) => apiGet(`/images/${id}`),

  // 根据图片码获取图片
  getImageByCode: (code: string) => apiGet(`/images/code/${code}`),

  // 删除图片
  deleteImage: (id: number) => apiDelete(`/images/${id}`),
};
