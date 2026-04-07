import dayjs from 'dayjs'

export function formatDate(date: string | null | undefined, fmt = 'YYYY-MM-DD HH:mm') {
  return date ? dayjs(date).format(fmt) : '-'
}

export function formatMoney(amount: number | null | undefined) {
  if (amount == null) return '-'
  return `¥${amount.toLocaleString('zh-CN', { minimumFractionDigits: 2 })}`
}

export function maskPhone(phone: string) {
  if (!phone || phone.length < 7) return phone || '-'
  return phone.replace(/(\d{3})\d{4}(\d+)/, '$1****$2')
}

export function formatFileSize(bytes: number | null | undefined) {
  if (bytes == null || bytes < 0) return '-'
  const units = ['B', 'KB', 'MB', 'GB']
  let n = bytes
  let i = 0
  while (n >= 1024 && i < units.length - 1) {
    n /= 1024
    i++
  }
  return `${n.toFixed(i === 0 ? 0 : 1)} ${units[i]}`
}
