import { useState, type FormEvent } from 'react'
import Logo from '../components/Logo'
import { authService, isMock } from '../services/api'
import type { User } from '../types'

export default function Login({ onLogin }: { onLogin: (u: User) => void }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      onLogin(await authService.login({ username: username.trim(), password }))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível entrar. Tente novamente.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="login">
      <section className="login-hero" aria-hidden="true">
        <Logo size={56} />
        <h1>Dado Seguro</h1>
        <p>Envie, guarde e compartilhe arquivos com controle de acesso e registro de cada ação.</p>
        <ul>
          <li>Arquivos criptografados</li>
          <li>Permissões por pessoa e equipe</li>
          <li>Auditoria de uploads e downloads</li>
        </ul>
      </section>

      <section className="login-panel">
        <form className="login-card" onSubmit={handleSubmit}>
          <h2>Entrar</h2>
          <p className="muted">Use sua conta autorizada para acessar os arquivos.</p>

          <label htmlFor="username">Usuário</label>
          <input id="username" value={username} onChange={(e) => setUsername(e.target.value)} autoComplete="username" required disabled={loading} />

          <label htmlFor="password">Senha</label>
          <input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" required disabled={loading} />

          {error && <p className="error" role="alert">{error}</p>}

          <button className="btn primary block" type="submit" disabled={loading}>
            {loading ? 'Entrando…' : 'Entrar'}
          </button>

          {isMock && <p className="hint">Modo demonstração: usuário <b>demo</b>, senha <b>demo123</b>.</p>}
        </form>
      </section>
    </main>
  )
}
