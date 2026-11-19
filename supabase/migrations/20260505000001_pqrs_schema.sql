-- Migration: 20260505000001_pqrs_schema
-- Purpose  : PQRS submissions table for LGL-05 compliance
--            (Peticiones, Quejas, Reclamos y Sugerencias — Ley 1480 de 2011)
--            Also used as audit trail for habeas-data requests (Ley 1581 de 2012).

CREATE TABLE IF NOT EXISTS pqrs_submissions (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  kind        TEXT        NOT NULL CHECK (kind IN ('peticion','queja','reclamo','sugerencia')),
  subject     TEXT        NOT NULL,
  body        TEXT        NOT NULL,
  email       TEXT        NOT NULL,
  order_id    UUID        REFERENCES orders(id) ON DELETE SET NULL,
  status      TEXT        NOT NULL DEFAULT 'received',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

ALTER TABLE pqrs_submissions ENABLE ROW LEVEL SECURITY;

-- User can insert their own submissions
CREATE POLICY "pqrs_insert_own" ON pqrs_submissions FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- User can read their own submissions
CREATE POLICY "pqrs_select_own" ON pqrs_submissions FOR SELECT
  USING (user_id = auth.uid());

-- No UPDATE/DELETE from client — operator manages via service_role

-- Index for efficient per-user queries
CREATE INDEX IF NOT EXISTS pqrs_submissions_user_id_idx
  ON pqrs_submissions (user_id);

CREATE INDEX IF NOT EXISTS pqrs_submissions_created_at_idx
  ON pqrs_submissions (created_at DESC);
