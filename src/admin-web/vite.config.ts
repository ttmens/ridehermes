import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  base: '/',
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    // 代码分割配置
    rollupOptions: {
      output: {
        manualChunks: {
          // 将大型依赖拆分为独立 chunk（避免循环依赖）
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-antd': ['antd', '@ant-design/icons'],
        },
      },
    },
    // 资源内联阈值（小于 4kb 的资源内联）
    assetsInlineLimit: 4096,
  },
  server: {
    port: 3001,
    proxy: {
      // 代理 API 请求到后端服务器
      '/api/v1': {
        target: 'http://localhost:8686',
        changeOrigin: true,
      },
      // 不代理高德地图 SDK（直接访问）
    },
  },
});
