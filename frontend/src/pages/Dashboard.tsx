import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import Logo from '../components/Logo'
import { authService, fileService, isMock } from '../services/api'
import type { Access, AuditEntry, FileItem, User } from '../types'

const fmtSize = (b: number) =>
  b >= 1e6 ? `${(b / 1e6).toFixed(1)} MB` : b >= 1e3 ? `${Math.round(b / 1e3)} KB` : `${b} B`
const fmtDate = (iso: string) =>
  new Date(iso).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })

const actionLabel: Record<AuditEntry['action'], string> = {
  login: 'entrou', login_falhou: 'tentativa de login recusada', upload: 'enviou', download: 'baixou', exclusao: 'excluiu', logout: 'saiu',
}

export default function Dashboard({ user, onLogout }: { user: User; onLogout: () => void }) {
  const [files, setFiles] = useState<FileItem[]>([])
  const [audit, setAudit] = useState<AuditEntry[]>([])
  const [query, setQuery] = useState('')
  const [access, setAccess] = useState<Access>('privado')
  const [busy, setBusy] = useState(false)
  const [drag, setDrag] = useState(false)
  const [msg, setMsg] = useState<{ type: 'ok' | 'err'; text: string } | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const load = useCallback(async () => {
    try {
      const [f, a] = await Promise.all([fileService.list(), fileService.audit().catch(() => [])])
      setFiles(f)
      setAudit(a)
    } catch {
      setMsg({ type: 'err', text: 'Não foi possível carregar os arquivos. Verifique a conexão com o servidor.' })
    }
  }, [])

  useEffect(() => { load() }, [load])

  async function upload(list: FileList | null) {
    if (!list?.length) return
    setBusy(true)
    setMsg(null)
    try {
      for (const file of Array.from(list)) await fileService.upload(file, access)
      setMsg({ type: 'ok', text: `${list.length} arquivo(s) enviado(s).` })
      await load()
    } catch (e) {
      setMsg({ type: 'err', text: e instanceof Error ? e.message : 'Falha no envio.' })
    } finally {
      setBusy(false)
      if (inputRef.current) inputRef.current.value = ''
    }
  }

  async function remove(f: FileItem) {
    if (!confirm(`Excluir "${f.name}"? Esta ação não pode ser desfeita.`)) return
    try {
      await fileService.remove(f.id)
      setMsg({ type: 'ok', text: 'Arquivo excluído.' })
      await load()
    } catch (e) {
      setMsg({ type: 'err', text: e instanceof Error ? e.message : 'Falha ao excluir.' })
    }
  }

  async function logout() {
    await authService.logout().catch(() => undefined)
    onLogout()
  }

  const visible = useMemo(() => files.filter((f) => f.name.toLowerCase().includes(query.toLowerCase())), [files, query])
  const total = files.reduce((s, f) => s + f.size, 0)
  const encrypted = files.filter((f) => f.encrypted).length
  const denied = audit.filter((a) => !a.ok).length
  const canDelete = (f: FileItem) => user.role === 'admin' || f.owner === user.username

  return (
    <div className="shell">
      <header className="topbar">
        <div className="brand"><Logo size={34} /><strong>Dado Seguro</strong></div>
        <div className="who">
          <span>{user.username} <small className="pill">{user.role === 'admin' ? 'Administrador' : 'Usuário'}</small></span>
          <button className="btn ghost" onClick={logout}>Sair</button>
        </div>
      </header>

      <main className="content">
        <h1>Arquivos</h1>

        <section className="stats" aria-label="Resumo">
          <div className="stat"><span>Arquivos</span><strong>{files.length}</strong></div>
          <div className="stat"><span>Espaço usado</span><strong>{fmtSize(total)}</strong></div>
          <div className="stat"><span>Criptografados</span><strong>{encrypted}/{files.length}</strong></div>
          <div className={`stat ${denied ? 'warn' : ''}`}><span>Acessos recusados</span><strong>{denied}</strong></div>
        </section>

        {msg && <p className={`banner ${msg.type}`} role="status">{msg.text}</p>}

        <div className="grid">
          <div className="col">
            <section
              className={`drop ${drag ? 'over' : ''}`}
              onDragOver={(e) => { e.preventDefault(); setDrag(true) }}
              onDragLeave={() => setDrag(false)}
              onDrop={(e) => { e.preventDefault(); setDrag(false); upload(e.dataTransfer.files) }}
            >
              <p><strong>Arraste arquivos aqui</strong> ou</p>
              <input ref={inputRef} id="file" type="file" multiple hidden onChange={(e) => upload(e.target.files)} />
              <button className="btn primary" onClick={() => inputRef.current?.click()} disabled={busy}>
                {busy ? 'Enviando…' : 'Escolher arquivos'}
              </button>
              <label className="inline">
                Quem pode ver
                <select value={access} onChange={(e) => setAccess(e.target.value as Access)}>
                  <option value="privado">Só eu e administradores</option>
                  <option value="equipe">Toda a equipe</option>
                </select>
              </label>
            </section>

            <section className="panel">
              <div className="panel-head">
                <h2>Seus arquivos</h2>
                <input type="search" placeholder="Buscar por nome" aria-label="Buscar por nome" value={query} onChange={(e) => setQuery(e.target.value)} />
              </div>
              {visible.length === 0 ? (
                <p className="empty">{files.length ? 'Nenhum arquivo com esse nome.' : 'Nenhum arquivo ainda. Envie o primeiro acima.'}</p>
              ) : (
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Nome</th><th>Tamanho</th><th>Dono</th><th>Acesso</th><th>Enviado</th><th><span className="sr">Ações</span></th></tr></thead>
                    <tbody>
                      {visible.map((f) => (
                        <tr key={f.id}>
                          <td className="name">{f.name}{f.encrypted && <span title="Criptografado"> 🔒</span>}</td>
                          <td>{fmtSize(f.size)}</td>
                          <td>{f.owner}</td>
                          <td><span className={`pill ${f.access}`}>{f.access === 'equipe' ? 'Equipe' : 'Privado'}</span></td>
                          <td>{fmtDate(f.uploadedAt)}</td>
                          <td className="actions">
                            <a className="btn small" href={fileService.downloadUrl(f.id)} onClick={(e) => { if (isMock) { e.preventDefault(); setMsg({ type: 'ok', text: 'Download simulado (modo demonstração).' }) } }}>Baixar</a>
                            {canDelete(f) && <button className="btn small danger" onClick={() => remove(f)}>Excluir</button>}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>
          </div>

          <aside className="col side">
            <section className="panel">
              <h2>Conexão SFTP</h2>
              <p className="muted">Para enviar arquivos grandes pelo seu cliente SFTP.</p>
              <dl className="kv">
                <dt>Servidor</dt><dd>{import.meta.env.VITE_SFTP_HOST || 'a definir'}</dd>
                <dt>Porta</dt><dd>22</dd>
                <dt>Autenticação</dt><dd>Chave SSH</dd>
              </dl>
            </section>

            <section className="panel">
              <h2>Atividade recente</h2>
              {audit.length === 0 ? (
                <p className="empty">Nenhuma atividade registrada.</p>
              ) : (
                <ul className="log">
                  {audit.slice(0, 8).map((a) => (
                    <li key={a.id} className={a.ok ? '' : 'bad'}>
                      <span><b>{a.user}</b> {actionLabel[a.action]}{a.target ? ` ${a.target}` : ''}</span>
                      <time>{fmtDate(a.at)}</time>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          </aside>
        </div>
      </main>
    </div>
  )
}
