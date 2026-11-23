import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Em desenvolvimento, as chamadas /api são encaminhadas ao backend (VITE_DEV_PROXY).
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  server: {
    proxy:
      mode === 'development' && process.env.VITE_DEV_PROXY
        ? { '/api': { target: process.env.VITE_DEV_PROXY, changeOrigin: true } }
        : undefined,
  },
}))
