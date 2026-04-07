import { ref, reactive, type Ref } from 'vue'
import { ElMessage } from 'element-plus'

interface TableMeta {
  page: number
  page_size: number
  total: number
}

export function useTable<T>(
  fetchFn: (params: Record<string, any>) => Promise<any>,
) {
  const loading = ref(false)
  const tableData: Ref<T[]> = ref([])
  const pagination = reactive<TableMeta>({
    page: 1,
    page_size: 20,
    total: 0,
  })

  let currentFilters: Record<string, any> = {}
  let requestId = 0

  async function loadData(extraParams: Record<string, any> = {}) {
    currentFilters = extraParams
    loading.value = true
    const thisRequest = ++requestId
    try {
      const params = {
        page: pagination.page,
        page_size: pagination.page_size,
        ...extraParams,
      }
      const res = await fetchFn(params)
      if (thisRequest !== requestId) return
      tableData.value = res.data ?? []
      pagination.total = res.meta?.total ?? tableData.value.length
    } catch (e) {
      if (thisRequest !== requestId) return
      tableData.value = []
      pagination.total = 0
      if (e instanceof Error && !e.message?.includes('401')) {
        ElMessage.error('加载数据失败，请重试')
      }
    } finally {
      if (thisRequest === requestId) {
        loading.value = false
      }
    }
  }

  function handlePageChange(page: number) {
    pagination.page = page
    loadData(currentFilters)
  }

  function handleSizeChange(size: number) {
    pagination.page_size = size
    pagination.page = 1
    loadData(currentFilters)
  }

  function refresh() {
    loadData(currentFilters)
  }

  return {
    loading,
    tableData,
    pagination,
    loadData,
    handlePageChange,
    handleSizeChange,
    refresh,
  }
}
