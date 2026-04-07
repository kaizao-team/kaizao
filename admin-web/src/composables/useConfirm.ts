import { ElMessageBox, ElMessage } from 'element-plus'

export function useConfirm() {
  async function confirmAction(
    message: string,
    action: () => Promise<any>,
    options?: { title?: string; successMsg?: string },
  ) {
    try {
      await ElMessageBox.confirm(message, options?.title || '确认操作', {
        confirmButtonText: '确认',
        cancelButtonText: '取消',
        type: 'warning',
      })
    } catch {
      return false
    }
    try {
      await action()
      ElMessage.success(options?.successMsg || '操作成功')
      return true
    } catch {
      return false
    }
  }

  return { confirmAction }
}
