export type TagType = 'success' | 'warning' | 'info' | 'danger' | 'primary' | undefined

export const USER_ROLES: Record<number, string> = {
  0: '未选角色',
  1: '项目方',
  2: '团队方',
  9: '管理员',
}

export const USER_STATUS: Record<number, { label: string; type: TagType }> = {
  0: { label: '已冻结', type: 'danger' },
  1: { label: '正常', type: 'success' },
}

export const ONBOARDING_STATUS: Record<number, { label: string; type: TagType }> = {
  0: { label: '未提交', type: 'info' },
  1: { label: '待审核', type: 'warning' },
  2: { label: '已通过', type: 'success' },
  3: { label: '已拒绝', type: 'danger' },
}

export const PROJECT_STATUS: Record<number, { label: string; type: TagType }> = {
  1: { label: '草稿', type: 'info' },
  2: { label: '已发布', type: undefined },
  3: { label: '匹配中', type: 'warning' },
  4: { label: '进行中', type: 'primary' },
  5: { label: '已完成', type: 'success' },
  6: { label: '已关闭', type: 'danger' },
}

export const ORDER_STATUS: Record<number, { label: string; type: TagType }> = {
  1: { label: '待支付', type: 'warning' },
  2: { label: '已支付', type: undefined },
  3: { label: '托管中', type: 'primary' },
  4: { label: '已释放', type: 'success' },
  5: { label: '已退款', type: 'info' },
  6: { label: '已过期', type: 'danger' },
}

export const REPORT_STATUS: Record<number, { label: string; type: TagType }> = {
  1: { label: '待处理', type: 'warning' },
  2: { label: '已处理', type: 'success' },
}

export const ARBITRATION_STATUS: Record<number, { label: string; type: TagType }> = {
  1: { label: '待处理', type: 'warning' },
  2: { label: '已裁决', type: 'success' },
}

export const REVIEW_STATUS: Record<number, { label: string; type: TagType }> = {
  1: { label: '正常', type: 'success' },
  2: { label: '已隐藏', type: 'info' },
}
