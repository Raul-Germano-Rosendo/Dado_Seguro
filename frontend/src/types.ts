export type Role = 'admin' | 'user'

export interface User {
  username: string
  role: Role
}

export interface LoginCredentials {
  username: string
  password: string
}

export type Access = 'privado' | 'equipe'

export interface FileItem {
  id: string
  name: string
  size: number // bytes
  owner: string
  uploadedAt: string // ISO 8601
  encrypted: boolean
  access: Access
}

export interface AuditEntry {
  id: string
  at: string // ISO 8601
  user: string
  action: 'login' | 'login_falhou' | 'upload' | 'download' | 'exclusao' | 'logout'
  target?: string
  ok: boolean
}
