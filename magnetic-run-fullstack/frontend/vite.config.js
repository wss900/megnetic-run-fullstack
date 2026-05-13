import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// CloudBase 等子路径部署：构建环境变量 VITE_BASE_PATH=/magnetic-run/（须带首尾斜杠按 Vite 要求）
const base = process.env.VITE_BASE_PATH || '/'

const apiBase = (process.env.VITE_API_BASE || '').trim()
if (apiBase && /\.app\.tcloudbase\.com/i.test(apiBase)) {
  throw new Error(
    'VITE_API_BASE 指向了静态托管域名（*.app.tcloudbase.com），接口请求会打到静态站而非 HTTP 云函数。' +
      '请改为控制台「HTTP 访问」中的域名，例如 https://<环境ID>.service.tcloudbase.com/my-api（与 HTTP_ROUTE_PREFIX 一致）。',
  )
}

// https://vite.dev/config/
export default defineConfig({
  base,
  plugins: [vue()],
  server: {
    proxy: {
      '/api': { target: 'http://127.0.0.1:8000', changeOrigin: true },
    },
  },
})
