import { createRouter, createWebHistory } from "vue-router";
import type { RouteRecordRaw } from "vue-router";
import Layout from "@/views/Layout.vue";
import { useAuthStore } from "@/stores/auth";

const routes: RouteRecordRaw[] = [
  {
    path: "/",
    component: Layout,
    redirect: "/dashboard",
    meta: { requiresAuth: true },
    children: [
      {
        path: "dashboard",
        name: "Dashboard",
        component: () => import("@/views/Dashboard.vue"),
        meta: { title: "仪表盘", icon: "Odometer", requiresAuth: true },
      },
      {
        path: "users",
        name: "Users",
        component: () => import("@/views/Users.vue"),
        meta: { title: "用户管理", icon: "User", requiresAuth: true },
      },
      {
        path: "images",
        name: "Images",
        component: () => import("@/views/Images.vue"),
        meta: { title: "图片管理", icon: "Picture", requiresAuth: true },
      },
      {
        path: "profile",
        name: "Profile",
        component: () => import("@/views/Profile.vue"),
        meta: { title: "个人信息", icon: "UserFilled", requiresAuth: true },
      },
    ],
  },
  {
    path: "/login",
    name: "Login",
    component: () => import("@/views/Login.vue"),
    meta: { requiresAuth: false },
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// 路由守卫
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore();

  // 如果路由需要认证
  if (to.meta.requiresAuth) {
    // 检查是否有token
    if (!authStore.token) {
      next("/login");
      return;
    }

    // 检查token是否有效
    const isValid = await authStore.checkAuth();
    if (!isValid) {
      next("/login");
      return;
    }
  }

  // 如果已登录且访问登录页，重定向到首页
  if (to.path === "/login" && authStore.token) {
    next("/");
    return;
  }

  next();
});

export default router;
