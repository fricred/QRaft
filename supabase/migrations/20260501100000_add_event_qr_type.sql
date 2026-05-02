-- Phase 2: Event QR type (documentation migration)
-- The qr_codes table stores qr_type as TEXT (no enum constraint).
-- QRType.event uses identifier 'vevent' — compatible with existing schema.
-- No ALTER TABLE required.
-- This migration is a schema-documentation checkpoint only.
SELECT 1; -- no-op
