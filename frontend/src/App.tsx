import { useEffect, useState } from 'react'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import { authService } from './services/api'
import type { User } from './types'

export default function App() {
  const [user, setUser] = useState<User | null>(null)
  const [checking, setChecking] = useState(true)

  useEffect(() => {
    authService.me().then(setUser).catch(() => setUser(null)).finally(() => setChecking(false))
  }, [])

  if (checking) return <div className="splash" role="status">Verificando sessão…</div>

  return user ? (
    <Dashboard user={user} onLogout={() => setUser(null)} />
  ) : (
    <Login onLogin={setUser} />
  )
}
