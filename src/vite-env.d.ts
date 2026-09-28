/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_DATA_MODE?: 'local' | 'api'
  readonly VITE_API_BASE_URL?: string
  readonly VITE_CLOUDFRONT_DOMAIN?: string
  readonly VITE_CORS_ORIGIN?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
