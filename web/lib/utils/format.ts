import dayjs from 'dayjs'
import 'dayjs/locale/zh-cn'
import relativeTime from 'dayjs/plugin/relativeTime'

dayjs.locale('zh-cn')
dayjs.extend(relativeTime)

export function formatRelative(input: string | number | Date): string {
  return dayjs(input).fromNow()
}

export function formatDate(input: string | number | Date, fmt = 'YYYY-MM-DD'): string {
  return dayjs(input).format(fmt)
}

export function formatMoney(cents: number): string {
  return `¥${(cents / 100).toLocaleString('zh-CN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`
}
