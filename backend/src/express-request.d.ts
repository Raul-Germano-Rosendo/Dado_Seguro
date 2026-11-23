import 'express'

declare module 'express-serve-static-core' {
  interface Request {
    currentUser?: {
      id: string
      username: string
      role: 'admin' | 'user'
    }
  }
}
