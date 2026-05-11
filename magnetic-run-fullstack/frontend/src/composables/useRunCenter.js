import { ref, computed, watch } from 'vue'
import axios from 'axios'

const apiBase = (import.meta.env.VITE_API_BASE || '').replace(/\/$/, '')
const http = axios.create({ baseURL: apiBase || undefined })

const steps = ref([])
const error = ref('')
const loadingList = ref(true)
const loadingRun = ref(false)
const result = ref(null)

const category = ref('')
const stepId = ref('')
const fileInput = ref(null)
const fileList = ref([])

const categories = computed(() => {
  const s = new Set(steps.value.map((x) => x.category))
  return [...s].sort()
})

const stepsInCat = computed(() => steps.value.filter((x) => x.category === category.value))

const currentStep = computed(() => steps.value.find((x) => x.id === stepId.value))

const paramValues = ref({})

watch(
  currentStep,
  (s) => {
    const o = {}
    if (!s) {
      paramValues.value = o
      return
    }
    for (const p of s.params) o[p.key] = p.default
    paramValues.value = o
    fileList.value = []
    if (fileInput.value) fileInput.value.value = ''
  },
  { immediate: true },
)

watch(
  steps,
  (list) => {
    if (list.length && !category.value) category.value = list[0].category
  },
  { immediate: true },
)

watch(category, () => {
  const first = stepsInCat.value[0]
  stepId.value = first ? first.id : ''
})

function apiErrorMessage(e) {
  const status = e.response?.status
  if (status === 502 || status === 503 || status === 504) {
    return `网关错误（${status}）：多为 API 未启动或未配置。本地请运行 start-backend.cmd；线上请在构建环境变量中设置 VITE_API_BASE 指向已部署的后端。`
  }
  if (status === 404) {
    return `未找到接口（404）：静态站点上没有 /api。请部署 backend（FastAPI）并设置 VITE_API_BASE，或确认后端路由与代理配置。`
  }
  const d = e.response?.data?.detail
  if (typeof d === 'string') return d
  if (d) return JSON.stringify(d)
  return e.message || String(e)
}

async function fetchSteps() {
  error.value = ''
  loadingList.value = true
  try {
    const { data } = await http.get('/api/steps')
    if (!Array.isArray(data)) {
      error.value = '步骤接口返回了非列表数据，请检查后端 /api/steps。'
      steps.value = []
      return
    }
    steps.value = data
  } catch (e) {
    error.value = apiErrorMessage(e)
  } finally {
    loadingList.value = false
  }
}

async function run() {
  error.value = ''
  result.value = null
  loadingRun.value = true
  try {
    const fd = new FormData()
    fd.append('step_id', stepId.value)
    fd.append('params_json', JSON.stringify(paramValues.value))
    for (const f of fileList.value) fd.append('files', f)
    const { data } = await http.post('/api/runs', fd)
    result.value = data
  } catch (e) {
    error.value = apiErrorMessage(e)
  } finally {
    loadingRun.value = false
  }
}

function onFiles(e) {
  fileList.value = e.target.files ? [...e.target.files] : []
}

const acceptAttr = computed(() => {
  const ft = currentStep.value?.file_types
  if (!ft?.length) return undefined
  return ft.map((x) => (x.startsWith('.') ? x : `.${x}`)).join(',')
})

function downloadLink(name, blob) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = name
  a.click()
  URL.revokeObjectURL(url)
}

function saveDownload(filename, mime, b64) {
  const bin = atob(b64)
  const bytes = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i)
  downloadLink(filename, new Blob([bytes], { type: mime || 'application/octet-stream' }))
}

export function useRunCenter() {
  return {
    steps,
    error,
    loadingList,
    loadingRun,
    result,
    category,
    stepId,
    fileInput,
    fileList,
    categories,
    stepsInCat,
    currentStep,
    paramValues,
    acceptAttr,
    fetchSteps,
    run,
    onFiles,
    saveDownload,
  }
}
