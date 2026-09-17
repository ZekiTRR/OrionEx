import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath } from 'node:url';
export default defineConfig({
  base: './', plugins: [react()],
  build: { target: 'chrome120', cssTarget: 'chrome120', outDir: 'dist', emptyOutDir: true,
    rollupOptions: { input: { main: fileURLToPath(new URL('./index.html', import.meta.url)), console: fileURLToPath(new URL('./console/index.html', import.meta.url)) } }
  }
});
