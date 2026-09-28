export interface Member {
  id: string
  name: string
  role: string
  bio: string
  photoKey: string
  photoUrl?: string // Generated from photoKey and CDN domain
}

export interface APIResponse {
  success: boolean
  data?: Member[]
  error?: string
  timestamp?: string
}
