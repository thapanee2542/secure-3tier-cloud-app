import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    proxy: {
      '/members': {
        target: 'https://dqumwr9ju6.execute-api.ap-southeast-7.amazonaws.com',
        changeOrigin: true,
        rewrite: (path) => `/dev${path}`,
      },
    },
  },
});