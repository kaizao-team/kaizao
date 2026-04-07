import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const AdminLayout = () => import('@/layouts/AdminLayout.vue')
const BlankLayout = () => import('@/layouts/BlankLayout.vue')

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    component: BlankLayout,
    children: [
      {
        path: '',
        name: 'Login',
        component: () => import('@/views/login/LoginView.vue'),
      },
    ],
  },
  {
    path: '/',
    component: AdminLayout,
    redirect: '/dashboard',
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/DashboardView.vue'),
        meta: { title: '数据看板', icon: 'DataAnalysis' },
      },
      {
        path: 'users',
        name: 'UserList',
        component: () => import('@/views/users/UserListView.vue'),
        meta: { title: '用户管理', icon: 'User' },
      },
      {
        path: 'users/:uuid',
        name: 'UserDetail',
        component: () => import('@/views/users/UserDetailView.vue'),
        meta: { title: '用户详情', hidden: true },
      },
      {
        path: 'onboarding',
        name: 'Onboarding',
        component: () => import('@/views/onboarding/OnboardingListView.vue'),
        meta: { title: '入驻审核', icon: 'Check' },
      },
      {
        path: 'projects',
        name: 'ProjectList',
        component: () => import('@/views/projects/ProjectListView.vue'),
        meta: { title: '项目管理', icon: 'Document' },
      },
      {
        path: 'projects/:uuid',
        name: 'ProjectDetail',
        component: () => import('@/views/projects/ProjectDetailView.vue'),
        meta: { title: '项目详情', hidden: true },
      },
      {
        path: 'teams',
        name: 'TeamList',
        component: () => import('@/views/teams/TeamListView.vue'),
        meta: { title: '团队管理', icon: 'UserFilled' },
      },
      {
        path: 'teams/:uuid',
        name: 'TeamDetail',
        component: () => import('@/views/teams/TeamDetailView.vue'),
        meta: { title: '团队详情', hidden: true },
      },
      {
        path: 'orders',
        name: 'OrderList',
        component: () => import('@/views/orders/OrderListView.vue'),
        meta: { title: '订单管理', icon: 'ShoppingCart' },
      },
      {
        path: 'invite-codes',
        name: 'InviteCodeList',
        component: () => import('@/views/invite-codes/InviteCodeListView.vue'),
        meta: { title: '邀请码管理', icon: 'Key' },
      },
      {
        path: 'reports',
        name: 'ReportList',
        component: () => import('@/views/reports/ReportListView.vue'),
        meta: { title: '举报管理', icon: 'Warning' },
      },
      {
        path: 'arbitrations',
        name: 'ArbitrationList',
        component: () => import('@/views/reports/ArbitrationListView.vue'),
        meta: { title: '仲裁管理', icon: 'Scale' },
      },
      {
        path: 'reviews',
        name: 'ReviewList',
        component: () => import('@/views/reviews/ReviewListView.vue'),
        meta: { title: '评价管理', icon: 'ChatDotRound' },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, _from, next) => {
  const token = localStorage.getItem('admin_token')
  const requiresAuth = to.matched.some((r) => r.meta.requiresAuth)
  if (requiresAuth && !token) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
  } else if (to.name === 'Login' && token) {
    next({ name: 'Dashboard' })
  } else {
    next()
  }
})

export default router
