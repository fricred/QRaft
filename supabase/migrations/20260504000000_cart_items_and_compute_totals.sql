-- =============================================================================
-- Migration: 20260504000000_cart_items_and_compute_totals
-- Purpose  : Phase 8 cart — persistent cross-device cart + server-authoritative
--            order total computation.
-- Apply    : Supabase Dashboard → SQL Editor (manual; CLI not configured).
-- Depends  : product_variants table (20260501000000_marketplace_catalog.sql)
--            qr_codes table (20250728000000_add_qr_codes_table.sql)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- NOTE on price_cop units
-- price_cop in product_variants stores WHOLE COP PESOS (e.g. 89000 = $89,000).
-- The Wompi multiply-by-100 (pesos → centavos) happens at checkout in Phase 9
-- inside the create_payment_intent Edge Function — NEVER here.
-- ---------------------------------------------------------------------------

-- =============================================================================
-- TABLE: cart_items
-- =============================================================================

CREATE TABLE IF NOT EXISTS cart_items (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_variant_id      UUID        NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  qr_code_id              UUID        NOT NULL REFERENCES qr_codes(id) ON DELETE CASCADE,
  customization_snapshot  JSONB       NOT NULL,    -- frozen QRCustomization at add-to-cart time
  png_storage_url         TEXT,                    -- null until Phase 8 Plan 03 uploads the engraver PNG
  quantity                INT         NOT NULL DEFAULT 1 CHECK (quantity > 0),
  added_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, product_variant_id, qr_code_id)
);

CREATE INDEX IF NOT EXISTS idx_cart_items_user ON cart_items(user_id);

-- =============================================================================
-- ROW LEVEL SECURITY: cart_items
-- Only the owning user may read or modify their own cart rows.
-- =============================================================================

ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- SELECT: user can only see their own cart items
CREATE POLICY "cart_items_select_own"
  ON cart_items FOR SELECT
  USING (user_id = auth.uid());

-- INSERT: user can only insert rows where user_id matches their auth identity
CREATE POLICY "cart_items_insert_own"
  ON cart_items FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- UPDATE: user can only update their own rows
CREATE POLICY "cart_items_update_own"
  ON cart_items FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: user can only delete their own rows
CREATE POLICY "cart_items_delete_own"
  ON cart_items FOR DELETE
  USING (user_id = auth.uid());

-- =============================================================================
-- FUNCTION: server_compute_order_totals
-- Returns server-authoritative cart totals for a given user.
-- Never call client-side float arithmetic for totals — Anti-Pattern 5 mitigation.
--
-- IVA rate: 19% (Colombian standard IVA, rounded to nearest whole peso)
-- Envío:    15,000 COP flat rate (Phase 9 may introduce address-based rates)
-- Total:    subtotal + iva + envio
--
-- SECURITY DEFINER: runs with definer's privileges so it can JOIN
-- product_variants (which has no user-level SELECT RLS) while still
-- scoping computation to p_user_id via the WHERE guard. The WHERE clause
-- prevents any cross-user data leakage.
-- =============================================================================

CREATE OR REPLACE FUNCTION server_compute_order_totals(p_user_id UUID)
RETURNS TABLE (
  subtotal_cop INT,
  iva_cop      INT,
  envio_cop    INT,
  total_cop    INT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_subtotal INT;
  v_iva      INT;
  v_envio    INT;
BEGIN
  -- Sum (price × quantity) for all of this user's cart items via product_variants JOIN.
  -- WHERE ci.user_id = p_user_id is the cross-user data isolation guard.
  SELECT COALESCE(SUM(pv.price_cop * ci.quantity), 0)
    INTO v_subtotal
    FROM cart_items ci
    JOIN product_variants pv ON pv.id = ci.product_variant_id
   WHERE ci.user_id = p_user_id;

  -- IVA 19% — ROUND to nearest whole peso (COP has no sub-peso denomination)
  v_iva   := ROUND(v_subtotal * 0.19);

  -- Flat shipping rate in whole COP pesos.
  -- Phase 9 may replace with address-based calculation when shipping zones are added.
  v_envio := 15000;

  RETURN QUERY SELECT v_subtotal, v_iva, v_envio, (v_subtotal + v_iva + v_envio);
END;
$$;
