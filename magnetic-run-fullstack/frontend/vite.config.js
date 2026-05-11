import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// CloudBase 等子路径部署：构建环境变量 VITE_BASE_PATH=/magnetic-run/（须带首尾斜杠按 Vite 要求）
const base = process.env.VITE_BASE_PATH || '/'

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
