-- =============================================================================
-- Migration: 20260510000000_notifications_fcm_schema.sql
-- Phase 10 Plan 01 — FCM token storage + notifications pipeline
-- =============================================================================
-- Apply via: Supabase Dashboard → SQL Editor
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLE: user_fcm_tokens
-- Stores per-device FCM registration tokens for push notifications.
-- RLS: authenticated users can only read/write their own rows.
-- Uniqueness on (user_id, token) prevents duplicate registrations.
-- The send-fcm Edge Function (Plan 04) deletes tokens that fail 3+ times.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token         TEXT        NOT NULL,
  platform      TEXT        NOT NULL CHECK (platform IN ('ios', 'android')),
  device_label  TEXT,
  last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- Enable Row-Level Security
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- SELECT: user reads their own tokens
CREATE POLICY "user_fcm_tokens_select_own"
  ON user_fcm_tokens
  FOR SELECT
  USING (user_id = auth.uid());

-- INSERT: user registers their own token
CREATE POLICY "user_fcm_tokens_insert_own"
  ON user_fcm_tokens
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- UPDATE: user refreshes last_seen_at on their own token
CREATE POLICY "user_fcm_tokens_update_own"
  ON user_fcm_tokens
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: user removes stale tokens for their own account
CREATE POLICY "user_fcm_tokens_delete_own"
  ON user_fcm_tokens
  FOR DELETE
  USING (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- TABLE: notifications
-- Stores outbound push notification records for the FCM pipeline.
-- RLS: authenticated users can SELECT their own rows only.
--      INSERT/UPDATE/DELETE are reserved for service_role (Edge Function).
-- fcm_state lifecycle: pending → sent | failed
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS notifications (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id    UUID        REFERENCES orders(id) ON DELETE SET NULL,
  kind        TEXT        NOT NULL,
  -- Allowed kinds: 'payment_approved', 'order_received', 'order_engraving',
  --                'order_engraving_done', 'order_shipped', 'order_delivered'
  title_es    TEXT        NOT NULL,
  body_es     TEXT        NOT NULL,
  data        JSONB,                  -- e.g. {"order_id": "...", "order_number": "..."}
  fcm_state   TEXT        NOT NULL DEFAULT 'pending'
                          CHECK (fcm_state IN ('pending', 'sent', 'failed')),
  fcm_retries INT         NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  sent_at     TIMESTAMPTZ,
  read_at     TIMESTAMPTZ
);

-- Index: send-fcm Edge Function scans for pending rows per user
CREATE INDEX IF NOT EXISTS idx_notifications_user_pending
  ON notifications(user_id, fcm_state, created_at)
  WHERE fcm_state = 'pending';

-- Index: look up notifications by order
CREATE INDEX IF NOT EXISTS idx_notifications_order
  ON notifications(order_id);

-- Enable Row-Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- SELECT: user reads their own notification history
CREATE POLICY "notifications_select_own"
  ON notifications
  FOR SELECT
  USING (user_id = auth.uid());

-- No INSERT / UPDATE / DELETE policies for the authenticated role.
-- Only the service_role key (used by the send-fcm Edge Function) may write
-- to this table.  Attempting to insert from the Flutter client will be
-- rejected by RLS.

-- =============================================================================
-- HOW THIS MIGRATION FITS INTO PHASE 10
-- =============================================================================
--
-- Plan 01 (this migration): creates tables + RLS
-- Plan 02: order status realtime subscription (reads notifications SELECT)
-- Plan 03: flutter_local_notifications foreground overlay
-- Plan 04: send-fcm Edge Function
--          - Triggered by a DB webhook on notifications INSERT
--          - Reads `notifications WHERE fcm_state = 'pending'`
--          - Sends FCM push via Firebase Admin SDK
--          - Upserts `fcm_state = 'sent'` (or 'failed') using service_role key
--          - Deletes user_fcm_tokens rows that have failed 3+ times
--
-- DB webhook (Plan 04): Supabase Dashboard → Database → Webhooks
--   Table: notifications  Event: INSERT  Target: send-fcm Edge Function URL
--
-- =============================================================================
