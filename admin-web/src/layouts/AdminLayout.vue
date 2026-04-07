<template>
  <el-container class="admin-layout">
    <el-aside :width="isCollapsed ? '64px' : '240px'" class="admin-aside">
      <div
        class="logo-area"
        role="button"
        tabindex="0"
        aria-label="返回首页"
        @click="router.push('/dashboard')"
        @keydown.enter="router.push('/dashboard')"
        @keydown.space.prevent="router.push('/dashboard')"
      >
        <div class="logo-mark">K</div>
        <transition name="fade">
          <span v-if="!isCollapsed" class="logo-text">开造后管</span>
        </transition>
      </div>

      <el-scrollbar class="menu-scrollbar">
        <el-menu
          :default-active="activeMenu"
          :collapse="isCollapsed"
          :collapse-transition="false"
          router
          class="admin-menu"
        >
          <template v-for="group in menuGroups" :key="group.label">
            <div v-if="!isCollapsed" class="menu-group-label">{{ group.label }}</div>
            <el-menu-item
              v-for="item in group.items"
              :key="item.path"
              :index="item.path"
              class="admin-menu-item"
            >
              <el-icon :size="18">
                <component :is="item.icon" />
              </el-icon>
              <template #title>{{ item.title }}</template>
            </el-menu-item>
          </template>
        </el-menu>
      </el-scrollbar>

      <div class="aside-footer">
        <div
          class="collapse-trigger"
          role="button"
          tabindex="0"
          :aria-label="isCollapsed ? '展开侧边栏' : '收起侧边栏'"
          @click="isCollapsed = !isCollapsed"
          @keydown.enter="isCollapsed = !isCollapsed"
          @keydown.space.prevent="isCollapsed = !isCollapsed"
        >
          <el-icon :size="16">
            <Fold v-if="!isCollapsed" />
            <Expand v-else />
          </el-icon>
          <span v-if="!isCollapsed" class="collapse-label">收起</span>
        </div>
      </div>
    </el-aside>

    <el-container class="main-container">
      <header class="admin-header">
        <div class="header-left">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item
              v-for="(crumb, idx) in breadcrumbs"
              :key="crumb.path"
              :to="idx < breadcrumbs.length - 1 ? { path: crumb.path } : undefined"
            >
              {{ crumb.title }}
            </el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-dropdown trigger="click">
            <div class="user-block">
              <div class="user-avatar">
                {{ (userStore.userInfo?.nickname || '管')[0] }}
              </div>
              <span v-if="!isCollapsed" class="user-name">
                {{ userStore.userInfo?.nickname || '管理员' }}
              </span>
              <el-icon :size="12"><ArrowDown /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item @click="handleLogout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <main class="admin-main">
        <router-view v-slot="{ Component }">
          <transition name="page-fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import {
  Fold,
  Expand,
  ArrowDown,
  SwitchButton,
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const isCollapsed = ref(false)

interface MenuItem {
  path: string
  title: string
  icon: string
}

interface MenuGroup {
  label: string
  items: MenuItem[]
}

const menuGroups: MenuGroup[] = [
  {
    label: '概览',
    items: [
      { path: '/dashboard', title: '数据看板', icon: 'DataAnalysis' },
    ],
  },
  {
    label: '用户',
    items: [
      { path: '/users', title: '用户管理', icon: 'User' },
      { path: '/onboarding', title: '入驻审核', icon: 'Check' },
    ],
  },
  {
    label: '业务',
    items: [
      { path: '/projects', title: '项目管理', icon: 'Document' },
      { path: '/teams', title: '团队管理', icon: 'UserFilled' },
      { path: '/orders', title: '订单管理', icon: 'ShoppingCart' },
    ],
  },
  {
    label: '运营',
    items: [
      { path: '/invite-codes', title: '邀请码', icon: 'Key' },
      { path: '/reports', title: '举报管理', icon: 'Warning' },
      { path: '/arbitrations', title: '仲裁管理', icon: 'Scale' },
      { path: '/reviews', title: '评价审核', icon: 'ChatDotRound' },
    ],
  },
]

const activeMenu = computed(() => {
  const path = route.path
  const topLevel = '/' + path.split('/').filter(Boolean)[0]
  return topLevel || '/dashboard'
})

const breadcrumbs = computed(() => {
  const matched = route.matched.filter((r) => r.meta?.title)
  return matched.map((r) => ({
    title: r.meta.title as string,
    path: r.path,
  }))
})


function handleLogout() {
  userStore.clearToken()
  router.push('/login')
}
</script>

<style scoped>
.admin-layout {
  min-height: 100vh;
  background: #f5f5f5;
}

.admin-aside {
  background: #111111;
  display: flex;
  flex-direction: column;
  transition: width 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
  position: fixed;
  left: 0;
  top: 0;
  bottom: 0;
  z-index: 100;
}

.main-container {
  margin-left: v-bind("isCollapsed ? '64px' : '240px'");
  transition: margin-left 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  flex-direction: column;
  min-height: 100vh;
}

.logo-area {
  height: 60px;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0 20px;
  cursor: pointer;
  flex-shrink: 0;
}

.logo-mark {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: linear-gradient(135deg, #ffffff 0%, #e0e0e0 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 16px;
  color: #111;
  flex-shrink: 0;
}

.logo-text {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  letter-spacing: 1px;
  white-space: nowrap;
}

.menu-scrollbar {
  flex: 1;
  overflow: hidden;
}

.menu-group-label {
  padding: 20px 24px 8px;
  font-size: 11px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.55);
  text-transform: uppercase;
  letter-spacing: 1.5px;
  white-space: nowrap;
}

.admin-menu {
  border-right: none;
  background: transparent !important;
}

.admin-menu :deep(.el-menu-item) {
  height: 42px;
  line-height: 42px;
  margin: 2px 8px;
  border-radius: 8px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  font-weight: 500;
  transition: all 0.2s;
}

.admin-menu :deep(.el-menu-item:hover) {
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
}

.admin-menu :deep(.el-menu-item.is-active) {
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  font-weight: 600;
}

.admin-menu :deep(.el-menu-item .el-icon) {
  color: inherit;
}

.aside-footer {
  flex-shrink: 0;
  padding: 12px 8px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
}

.collapse-trigger {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
  color: rgba(255, 255, 255, 0.4);
  font-size: 12px;
  transition: all 0.2s;
}

.collapse-trigger:hover {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.7);
}

.collapse-label {
  white-space: nowrap;
}

.admin-header {
  height: 56px;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  position: sticky;
  top: 0;
  z-index: 50;
  box-shadow: 0 1px 0 rgba(0, 0, 0, 0.04);
}

.header-left {
  display: flex;
  align-items: center;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-block {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 8px;
  transition: background 0.2s;
}

.user-block:hover {
  background: #f5f5f5;
}

.user-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #1a1c1c;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
}

.user-name {
  font-size: 13px;
  color: #333;
  font-weight: 500;
}

.admin-main {
  padding: 24px;
  flex: 1;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.page-fade-enter-active,
.page-fade-leave-active {
  transition: opacity 0.15s ease;
}
.page-fade-enter-from,
.page-fade-leave-to {
  opacity: 0;
}
</style>
