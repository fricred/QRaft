-- Link redirects to their source QR code
--
-- The redirects table only carried owner_id, so the app could not resolve
-- which QR a scanqraft.app/{slug} redirect belongs to. This FK enables:
--   * PostgREST embedded selects from qr_codes:
--       select('*, redirects(slug, scan_count, last_scanned_at)')
--   * Per-QR scan stats in the library UI (scan badge, analytics)
--   * Passing the real slug to RedirectEditScreen (closes the slug TODO)
--
-- qr_code_id is nullable: redirects minted before this migration (or created
-- outside an app flow) simply remain unlinked until backfilled.

ALTER TABLE redirects
  ADD COLUMN qr_code_id UUID REFERENCES qr_codes(id) ON DELETE SET NULL;

CREATE INDEX idx_redirects_qr_code_id ON redirects(qr_code_id);
