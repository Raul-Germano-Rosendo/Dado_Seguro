import type { Access, AuditEntry, FileItem, LoginCredentials, User } from '../types'

/**
 * Contrato esperado do backend (ajuste junto com o Raul):
 *   POST   /auth/login      {username,password} -> User        (cookie de sessão HttpOnly)
 *   POST   /auth/logout
 *   GET    /auth/me         -> User | 401
 *   GET    /files           -> FileItem[]
 *   POST   /files           multipart: file, access -> FileItem
 *   GET    /files/:id/download -> binário
 *   DELETE /files/:id
 *   GET    /audit           -> AuditEntry[]
 */
const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true'
const BASE = import.meta.env.VITE_API_URL || '/api'

export class ApiError extends Error {
  status: number
  constructor(message: string, status: number) {
    super(message)
    this.status = status
  }
}

async function http<T>(path: string, init: RequestInit = {}): Promise<T> {
  const isForm = init.body instanceof FormData
  const res = await fetch(`${BASE}${path}`, {
    credentials: 'include',
    ...init,
    headers: isForm ? init.headers : { 'Content-Type': 'application/json', ...init.headers },
  })
  if (!res.ok) {
    let msg = 'Falha na requisição'
    try {
      msg = (await res.json()).message ?? msg
    } catch { /* corpo vazio */ }
    throw new ApiError(msg, res.status)
  }
  return res.status === 204 ? (undefined as T) : ((await res.json()) as T)
}

/* ---------- Modo demonstração (dados fictícios, só em memória) ---------- */
const delay = (ms = 350) => new Promise((r) => setTimeout(r, ms))
let mockUser: User | null = null
let mockFiles: FileItem[] = [
  { id: 'f1', name: 'relatorio-trimestral.pdf', size: 2_450_000, owner: 'demo', uploadedAt: '2026-11-20T14:12:00Z', encrypted: true, access: 'equipe' },
  { id: 'f2', name: 'planilha-custos.xlsx', size: 480_000, owner: 'demo', uploadedAt: '2026-11-21T09:40:00Z', encrypted: true, access: 'privado' },
  { id: 'f3', name: 'contrato-fornecedor.docx', size: 125_000, owner: 'ana', uploadedAt: '2026-11-21T17:05:00Z', encrypted: true, access: 'equipe' },
]
let mockAudit: AuditEntry[] = []
const log = (action: AuditEntry['action'], user: string, ok = true, target?: string) =>
  mockAudit.unshift({ id: crypto.randomUUID(), at: new Date().toISOString(), user, action, target, ok })

const mock = {
  async login({ username, password }: LoginCredentials): Promise<User> {
    await delay()
    if (username === 'demo' && password === 'demo123') {
      mockUser = { username, role: 'admin' }
      log('login', username)
      return mockUser
    }
    log('login_falhou', username || 'desconhecido', false)
    throw new ApiError('Usuário ou senha incorretos.', 401)
  },
  async logout() { if (mockUser) log('logout', mockUser.username); mockUser = null },
  async me(): Promise<User> {
    if (!mockUser) throw new ApiError('Não autenticado', 401)
    return mockUser
  },
  async list(): Promise<FileItem[]> {
    await delay(200)
    return mockUser?.role === 'admin' ? [...mockFiles] : mockFiles.filter((f) => f.access === 'equipe' || f.owner === mockUser?.username)
  },
  async upload(file: File, access: Access): Promise<FileItem> {
    await delay(600)
    const item: FileItem = { id: crypto.randomUUID(), name: file.name, size: file.size, owner: mockUser!.username, uploadedAt: new Date().toISOString(), encrypted: true, access }
    mockFiles.unshift(item)
    log('upload', mockUser!.username, true, file.name)
    return item
  },
  async remove(id: string) {
    await delay(300)
    const f = mockFiles.find((x) => x.id === id)
    mockFiles = mockFiles.filter((x) => x.id !== id)
    log('exclusao', mockUser!.username, true, f?.name)
  },
  async audit(): Promise<AuditEntry[]> { await delay(150); return [...mockAudit] },
}

/* ---------- API pública ---------- */
export const authService = {
  login: (c: LoginCredentials) => (USE_MOCK ? mock.login(c) : http<User>('/auth/login', { method: 'POST', body: JSON.stringify(c) })),
  logout: () => (USE_MOCK ? mock.logout() : http<void>('/auth/logout', { method: 'POST' })),
  me: () => (USE_MOCK ? mock.me() : http<User>('/auth/me')),
}

export const fileService = {
  list: () => (USE_MOCK ? mock.list() : http<FileItem[]>('/files')),
  upload: (file: File, access: Access) => {
    if (USE_MOCK) return mock.upload(file, access)
    const body = new FormData()
    body.append('file', file)
    body.append('access', access)
    return http<FileItem>('/files', { method: 'POST', body })
  },
  remove: (id: string) => (USE_MOCK ? mock.remove(id) : http<void>(`/files/${id}`, { method: 'DELETE' })),
  downloadUrl: (id: string) => `${BASE}/files/${id}/download`,
  audit: () => (USE_MOCK ? mock.audit() : http<AuditEntry[]>('/audit')),
}

export const isMock = USE_MOCK
