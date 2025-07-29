import { defineStore } from "pinia";
import { ref } from "vue";
import { useRouter } from "vue-router";

export interface User {
  id: number;
  username: string;
  email: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export const useAuthStore = defineStore("auth", () => {
  const token = ref<string | null>(localStorage.getItem("token"));
  const user = ref<User | null>(null);
  const router = useRouter();

  // 设置token
  const setToken = (newToken: string) => {
    token.value = newToken;
    localStorage.setItem("token", newToken);
  };

  // 设置用户信息
  const setUser = (userInfo: User) => {
    user.value = userInfo;
  };

  // 登录
  const login = async (
    username: string,
    password: string
  ): Promise<boolean> => {
    try {
      const response = await fetch("/api/v1/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ username, password }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || "登录失败");
      }

      const data = await response.json();
      const loginData: LoginResponse = data.data;

      setToken(loginData.token);
      setUser(loginData.user);

      return true;
    } catch (error) {
      console.error("Login error:", error);
      throw error;
    }
  };

  // 登出
  const logout = () => {
    token.value = null;
    user.value = null;
    localStorage.removeItem("token");
    router.push("/login");
  };

  // 检查token是否有效
  const checkAuth = async (): Promise<boolean> => {
    if (!token.value) {
      return false;
    }

    try {
      const response = await fetch("/api/v1/auth/profile", {
        headers: {
          Authorization: `Bearer ${token.value}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setUser(data.data);
        return true;
      } else {
        // token无效，清除本地存储
        logout();
        return false;
      }
    } catch (error) {
      console.error("Auth check error:", error);
      logout();
      return false;
    }
  };

  // 获取用户信息
  const getProfile = async (): Promise<User | null> => {
    if (!token.value) {
      return null;
    }

    try {
      const response = await fetch("/api/v1/auth/profile", {
        headers: {
          Authorization: `Bearer ${token.value}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setUser(data.data);
        return data.data;
      } else {
        logout();
        return null;
      }
    } catch (error) {
      console.error("Get profile error:", error);
      logout();
      return null;
    }
  };

  return {
    token,
    user,
    login,
    logout,
    checkAuth,
    getProfile,
    setToken,
    setUser,
  };
});
