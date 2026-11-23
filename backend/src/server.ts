import bcrypt from 'bcryptjs'
import connectPgSimple from 'connect-pg-simple'
import express, { type ErrorRequestHandler, type Request, type Response } from 'express'
import session from 'express-session'
import { rateLimit } from 'express-rate-limit'
import helmet from 'helmet'
import multer from 'multer'
import { randomUUID } from 'node:crypto'
import { mkdir, unlink } from 'node:fs/promises'
import { readFileSync } from 'node:fs'
import path from 'node:path'
import pg from 'pg'

const { Pool } = pg
const app = express()
const port = Number(process.env.PORT ?? 3000)
const uploadDir = process.env.UPLOAD_DIR ?? '/app/uploads'
const readSecret = (name: string) => readFileSync(process.env[name]!, 'utf8').trimEnd()

const pool = new Pool({
  host: process.env.DB_HOST ?? 'db',
  port: Number(process.env.DB_PORT ?? 5432),
  database: process.env.DB_NAME ?? 'dadoseguro',
  user: process.env.DB_USER ?? 'dadoseguro_app',
  password: readSecret('DB_PASSWORD_FILE'),
  max: 5,
  connectionTimeoutMillis: 5000,
})

const schema = `
CREATE TABLE IF NOT EXISTS app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'user')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stored_files (
  id uuid PRIMARY KEY,
  owner_id uuid NOT NULL REFERENCES app_users(id),
  original_name text NOT NULL,
  stored_name text NOT NULL UNIQUE,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  access text NOT NULL CHECK (access IN ('privado', 'equipe')),
  encrypted boolean NOT NULL DEFAULT false,
  uploaded_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS stored_files_uploaded_at_idx ON stored_files (uploaded_at DESC);

CREATE TABLE IF NOT EXISTS audit_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES app_users(id) ON DELETE SET NULL,
  username text NOT NULL,
  action text NOT NULL CHECK (action IN ('login', 'login_falhou', 'upload', 'download', 'exclusao', 'logout')),
  target text,
  ok boolean NOT NULL,
  at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_entries_at_idx ON audit_entries (at DESC);
`

type AppUser = NonNullable<Request['currentUser']>

async function audit(user: AppUser | null, action: string, ok: boolean, target?: string) {
  await pool.query(
    'INSERT INTO audit_entries (user_id, username, action, target, ok) VALUES ($1, $2, $3, $4, $5)',
    [user?.id ?? null, user?.username ?? target ?? 'desconhecido', action, target ?? null, ok],
  )
}

function jsonUser(user: AppUser) {
  return { username: user.username, role: user.role }
}

async function requireUser(req: Request, res: Response, next: express.NextFunction) {
  if (!req.session.userId) return res.status(401).json({ message: 'Não autenticado.' })
  const result = await pool.query(
    'SELECT id, username, role FROM app_users WHERE id = $1',
    [req.session.userId],
  )
  if (!result.rowCount) {
    req.session.destroy(() => undefined)
    return res.status(401).json({ message: 'Sessão expirada.' })
  }
  req.currentUser = result.rows[0] as AppUser
  next()
}

function safeOriginalName(name: string) {
  const leaf = path.basename(name.replace(/\\/g, '/'))
  return leaf.replace(/[\u0000-\u001f\u007f]/g, '').slice(0, 240) || 'arquivo'
}

const storage = multer.diskStorage({
  destination: uploadDir,
  filename: (_req, _file, done) => done(null, randomUUID()),
})
const upload = multer({ storage, limits: { fileSize: 25 * 1024 * 1024, files: 1 } })
const PgStore = connectPgSimple(session)

app.disable('x-powered-by')
app.set('trust proxy', 2)
app.use(helmet({ strictTransportSecurity: false, contentSecurityPolicy: false }))
app.use(express.json({ limit: '32kb' }))
app.use(session({
  name: 'dado.sid',
  secret: readSecret('SESSION_SECRET_FILE'),
  store: new PgStore({ pool, tableName: 'app_sessions', createTableIfMissing: true, ttl: 8 * 60 * 60 }),
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.COOKIE_SECURE === 'true',
    maxAge: 8 * 60 * 60 * 1000,
  },
}))

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 8,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: (_req, res) => res.status(429).json({ message: 'Muitas tentativas. Aguarde 15 minutos.' }),
})

app.get('/healthz', async (_req, res) => {
  await pool.query('SELECT 1')
  res.json({ status: 'ok' })
})

app.post('/auth/login', loginLimiter, async (req, res) => {
  const username = typeof req.body?.username === 'string' ? req.body.username.trim().slice(0, 80) : ''
  const password = typeof req.body?.password === 'string' ? req.body.password : ''
  if (!username || !password || password.length > 256) {
    await audit(null, 'login_falhou', false, username || 'desconhecido')
    return res.status(401).json({ message: 'Usuário ou senha incorretos.' })
  }

  const result = await pool.query(
    'SELECT id, username, password_hash, role FROM app_users WHERE username = $1',
    [username],
  )
  const row = result.rows[0]
  if (!row || !(await bcrypt.compare(password, row.password_hash))) {
    await audit(null, 'login_falhou', false, username)
    return res.status(401).json({ message: 'Usuário ou senha incorretos.' })
  }

  await new Promise<void>((resolve, reject) => {
    req.session.regenerate((error) => error ? reject(error) : resolve())
  })
  const user = { id: row.id as string, username: row.username as string, role: row.role as AppUser['role'] }
  req.session.userId = user.id
  await audit(user, 'login', true)
  res.json(jsonUser(user))
})

app.post('/auth/logout', requireUser, async (req, res) => {
  await audit(req.currentUser!, 'logout', true)
  req.session.destroy((error) => {
    if (error) return res.status(500).json({ message: 'Não foi possível encerrar a sessão.' })
    res.clearCookie('dado.sid', { httpOnly: true, sameSite: 'lax' })
    res.status(204).end()
  })
})

app.get('/auth/me', requireUser, (req, res) => res.json(jsonUser(req.currentUser!)))

app.get('/files', requireUser, async (req, res) => {
  const user = req.currentUser!
  const result = await pool.query(
    `SELECT f.id, f.original_name, f.size_bytes, u.username AS owner, f.uploaded_at, f.encrypted, f.access
     FROM stored_files f JOIN app_users u ON u.id = f.owner_id
     WHERE $1 = 'admin' OR f.access = 'equipe' OR f.owner_id = $2
     ORDER BY f.uploaded_at DESC`,
    [user.role, user.id],
  )
  res.json(result.rows.map((row) => ({
    id: row.id,
    name: row.original_name,
    size: Number(row.size_bytes),
    owner: row.owner,
    uploadedAt: row.uploaded_at,
    encrypted: row.encrypted,
    access: row.access,
  })))
})

app.post('/files', requireUser, upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'Selecione um arquivo.' })
  const access = req.body?.access
  if (access !== 'privado' && access !== 'equipe') {
    await unlink(req.file.path).catch(() => undefined)
    return res.status(400).json({ message: 'Nível de acesso inválido.' })
  }

  const id = randomUUID()
  const name = safeOriginalName(req.file.originalname)
  try {
    const result = await pool.query(
      `INSERT INTO stored_files (id, owner_id, original_name, stored_name, size_bytes, access)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, original_name, size_bytes, uploaded_at, encrypted, access`,
      [id, req.currentUser!.id, name, req.file.filename, req.file.size, access],
    )
    await audit(req.currentUser!, 'upload', true, name)
    const row = result.rows[0]
    res.status(201).json({
      id: row.id,
      name: row.original_name,
      size: Number(row.size_bytes),
      owner: req.currentUser!.username,
      uploadedAt: row.uploaded_at,
      encrypted: row.encrypted,
      access: row.access,
    })
  } catch (error) {
    await unlink(req.file.path).catch(() => undefined)
    throw error
  }
})

app.get('/files/:id/download', requireUser, async (req, res, next) => {
  const user = req.currentUser!
  const result = await pool.query(
    `SELECT f.id, f.original_name, f.stored_name, f.access, u.username AS owner
     FROM stored_files f JOIN app_users u ON u.id = f.owner_id WHERE f.id = $1`,
    [req.params.id],
  )
  const file = result.rows[0]
  if (!file || (user.role !== 'admin' && file.access !== 'equipe' && file.owner !== user.username)) {
    return res.status(404).json({ message: 'Arquivo não encontrado.' })
  }
  await audit(user, 'download', true, file.original_name)
  res.download(path.join(uploadDir, file.stored_name), safeOriginalName(file.original_name), (error) => {
    if (error && !res.headersSent) next(error)
  })
})

app.delete('/files/:id', requireUser, async (req, res) => {
  const user = req.currentUser!
  const result = await pool.query(
    'SELECT id, owner_id, original_name, stored_name FROM stored_files WHERE id = $1',
    [req.params.id],
  )
  const file = result.rows[0]
  if (!file) return res.status(404).json({ message: 'Arquivo não encontrado.' })
  if (user.role !== 'admin' && file.owner_id !== user.id) {
    return res.status(403).json({ message: 'Somente o proprietário ou administrador pode excluir este arquivo.' })
  }
  await pool.query('DELETE FROM stored_files WHERE id = $1', [file.id])
  await unlink(path.join(uploadDir, file.stored_name)).catch((error: NodeJS.ErrnoException) => {
    if (error.code !== 'ENOENT') throw error
  })
  await audit(user, 'exclusao', true, file.original_name)
  res.status(204).end()
})

app.get('/audit', requireUser, async (req, res) => {
  if (req.currentUser!.role !== 'admin') return res.status(403).json({ message: 'Acesso restrito ao administrador.' })
  const result = await pool.query(
    'SELECT id, at, username AS user, action, target, ok FROM audit_entries ORDER BY at DESC LIMIT 100',
  )
  res.json(result.rows)
})

const errors: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ message: 'O limite por arquivo nesta demonstração é 25 MB.' })
  }
  console.error('API request failed:', error instanceof Error ? error.message : 'unknown error')
  res.status(500).json({ message: 'Erro interno. Tente novamente.' })
}
app.use(errors)

async function start() {
  await mkdir(uploadDir, { recursive: true, mode: 0o750 })
  await pool.query(schema)
  const adminPassword = readSecret('ADMIN_PASSWORD_FILE')
  if (adminPassword.length < 16) throw new Error('A senha inicial do administrador deve ter ao menos 16 caracteres.')
  const adminUsername = process.env.ADMIN_USERNAME ?? 'admin'
  const passwordHash = await bcrypt.hash(adminPassword, 12)
  await pool.query(
    `INSERT INTO app_users (username, password_hash, role) VALUES ($1, $2, 'admin')
     ON CONFLICT (username) DO NOTHING`,
    [adminUsername, passwordHash],
  )
  app.listen(port, '0.0.0.0', () => console.log(`Dado Seguro API listening on ${port}`))
}

start().catch((error: unknown) => {
  console.error('API startup failed:', error instanceof Error ? error.message : 'unknown error')
  process.exit(1)
})
