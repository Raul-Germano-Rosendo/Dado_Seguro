-- Dado Seguro: schema inicial PostgreSQL.
-- Pode ser reaplicado: CREATE TABLE/INDEX IF NOT EXISTS preserva os dados existentes.

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
CREATE INDEX IF NOT EXISTS stored_files_uploaded_at_idx
  ON stored_files (uploaded_at DESC);

CREATE TABLE IF NOT EXISTS audit_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES app_users(id) ON DELETE SET NULL,
  username text NOT NULL,
  action text NOT NULL CHECK (action IN ('login', 'login_falhou', 'upload', 'download', 'exclusao', 'logout')),
  target text,
  ok boolean NOT NULL,
  at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_entries_at_idx
  ON audit_entries (at DESC);

CREATE TABLE IF NOT EXISTS app_sessions (
  sid varchar NOT NULL COLLATE "default",
  sess json NOT NULL,
  expire timestamp(6) NOT NULL,
  CONSTRAINT app_sessions_pkey PRIMARY KEY (sid)
);
CREATE INDEX IF NOT EXISTS app_sessions_expire_idx
  ON app_sessions (expire);
