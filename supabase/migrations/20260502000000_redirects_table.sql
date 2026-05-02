-- Migration: 20260502000000_redirects_table.sql
-- Description: Creates the redirects table for qraft.link/{slug} infrastructure
-- Manual application required: Run in Supabase Dashboard → SQL Editor

CREATE TABLE redirects (
  id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  slug             TEXT         UNIQUE NOT NULL,
  destination_url  TEXT         NOT NULL,
  owner_id         UUID         REFERENCES auth.users(id) ON DELETE CASCADE,
  scan_count       INTEGER      DEFAULT 0,
  last_scanned_at  TIMESTAMPTZ,
  last_country     TEXT,
  created_at       TIMESTAMPTZ  DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

-- Fast slug lookup (the hot path: every QR scan hits this)
CREATE INDEX idx_redirects_slug ON redirects(slug);

-- Owner queries (user's redirect list)
CREATE INDEX idx_redirects_owner ON redirects(owner_id);

-- ---------------------------------------------------------------------------
-- Auto-update updated_at trigger
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_redirects_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_redirects_updated_at
  BEFORE UPDATE ON redirects
  FOR EACH ROW
  EXECUTE FUNCTION update_redirects_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

ALTER TABLE redirects ENABLE ROW LEVEL SECURITY;

-- Public SELECT: allows the redirect resolver to look up any slug without auth.
-- The Edge Function (or any unauthenticated client) can call:
--   .from('redirects').select('destination_url').eq('slug', slug).single()
CREATE POLICY "public_read_by_slug" ON redirects
  FOR SELECT
  USING (true);

-- INSERT: only authenticated users may create a redirect; owner_id must match
-- their own auth.uid() to prevent spoofing another user's owner_id.
CREATE POLICY "owner_insert" ON redirects
  FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- UPDATE: owners may update only their own rows.
CREATE POLICY "owner_update" ON redirects
  FOR UPDATE
  USING (auth.uid() = owner_id);

-- DELETE: owners may delete only their own rows.
CREATE POLICY "owner_delete" ON redirects
  FOR DELETE
  USING (auth.uid() = owner_id);
