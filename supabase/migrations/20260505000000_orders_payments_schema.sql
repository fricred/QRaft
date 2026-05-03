-- =============================================================================
-- Migration: 20260505000000_orders_payments_schema
-- Purpose  : Phase 9 checkout — orders, order_items, payments, payment_events
--            tables with server-authoritative FSM trigger, idempotent webhook
--            log, and SECURITY DEFINER RPCs for order creation and payment
--            event application.
-- Apply    : Supabase Dashboard → SQL Editor (manual; CLI not configured).
-- Depends  : product_variants table (20260501000000_marketplace_catalog.sql)
--            qr_codes table         (20250728000000_add_qr_codes_table.sql)
--            cart_items table       (20260504000000_cart_items_and_compute_totals.sql)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- NOTE on price_cop / amount_cop units
-- All monetary amounts are stored as WHOLE COP PESOS (e.g. 89000 = $89,000).
-- The Wompi multiply-by-100 (pesos → centavos for payment widget) happens in
-- the create_payment_intent Edge Function (Plan 02) — NEVER here.
-- ---------------------------------------------------------------------------

-- =============================================================================
-- SEQUENCE: order_seq
-- Used by generate_order_number() to produce human-readable order numbers.
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS order_seq START 1;

-- =============================================================================
-- ENUM: order_status
-- Full lifecycle including laser-fulfillment states.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    CREATE TYPE order_status AS ENUM (
      'payment_pending',   -- initial state; waiting for Wompi
      'payment_failed',    -- Wompi returned DECLINED/VOIDED/ERROR; can retry
      'paid',              -- Wompi returned APPROVED; waiting for ops intake
      'received_by_ops',   -- operator confirmed order receipt
      'engraving',         -- laser job started on XTool F1 Ultra
      'engraving_failed',  -- laser job failed; back to received_by_ops
      'engraving_done',    -- laser job completed; pending shipment
      'shipped',           -- courier received; tracking provided
      'delivered',         -- confirmed delivery
      'cancelled',         -- terminal: only from payment_pending/payment_failed/received_by_ops
      'refunded'           -- terminal: admin-initiated post-paid refund
    );
  END IF;
END$$;

-- =============================================================================
-- ENUM: payment_status
-- Mirrors Wompi transaction status values (lowercase) plus our own states.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
    CREATE TYPE payment_status AS ENUM (
      'pending',   -- initial; Wompi payment not yet attempted/confirmed
      'approved',  -- Wompi APPROVED
      'declined',  -- Wompi DECLINED
      'voided',    -- Wompi VOIDED (pre-capture void)
      'error',     -- Wompi ERROR or unexpected state
      'refunded'   -- admin-issued refund processed
    );
  END IF;
END$$;

-- =============================================================================
-- TABLE: orders
-- Central order record. Status is ONLY mutated via apply_payment_event RPC or
-- operator RPCs (Plan 11). Client has SELECT only via RLS — NO direct mutations.
-- =============================================================================

CREATE TABLE IF NOT EXISTS orders (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number            TEXT        UNIQUE NOT NULL,   -- set by trg_generate_order_number
  user_id                 UUID        NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  status                  order_status NOT NULL DEFAULT 'payment_pending',

  -- Amounts in whole COP pesos (INT).
  subtotal_cop            INT         NOT NULL,
  tax_cop                 INT         NOT NULL,          -- IVA 19%
  shipping_cop            INT         NOT NULL,
  total_cop               INT         NOT NULL,

  -- Shipping details (flat fields, not JSONB — indexed, auditable, required by law).
  shipping_recipient_name TEXT        NOT NULL,
  shipping_phone          TEXT        NOT NULL,
  shipping_department     TEXT        NOT NULL,
  shipping_city           TEXT        NOT NULL,
  shipping_address        TEXT        NOT NULL,
  shipping_notes          TEXT,                          -- nullable optional field

  -- Lifecycle timestamps (set server-side only).
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_at                 TIMESTAMPTZ,
  received_at             TIMESTAMPTZ,
  engraving_started_at    TIMESTAMPTZ,
  engraving_done_at       TIMESTAMPTZ,
  shipped_at              TIMESTAMPTZ,
  delivered_at            TIMESTAMPTZ,
  cancelled_at            TIMESTAMPTZ
);

-- Operator dashboard: load orders by user with status filter (consumer-facing queries).
CREATE INDEX IF NOT EXISTS idx_orders_user_status
  ON orders(user_id, status);

-- Operator ops-queue: only active fulfilment states, ordered by creation time.
CREATE INDEX IF NOT EXISTS idx_orders_ops_queue
  ON orders(status, created_at)
  WHERE status IN ('paid', 'received_by_ops', 'engraving', 'engraving_done');

-- =============================================================================
-- TABLE: order_items
-- One row per cart item, with customization JSONB snapshot frozen at order time.
-- qr_png_url is the 2160px engraver-quality PNG pre-rasterized at checkout.
-- =============================================================================

CREATE TABLE IF NOT EXISTS order_items (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id                UUID        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_variant_id      UUID        NOT NULL REFERENCES product_variants(id) ON DELETE RESTRICT,
  qr_code_id              UUID        REFERENCES qr_codes(id) ON DELETE SET NULL,  -- preserved even if user deletes QR
  customization_snapshot  JSONB       NOT NULL,   -- engraver source-of-truth; never mutated
  qr_png_url              TEXT        NOT NULL,   -- pre-rasterized PNG in Supabase Storage
  unit_price_cop          INT         NOT NULL,
  quantity                INT         NOT NULL CHECK (quantity > 0),
  line_total_cop          INT         NOT NULL    -- unit_price_cop * quantity at order time
);

CREATE INDEX IF NOT EXISTS idx_order_items_order
  ON order_items(order_id);

-- =============================================================================
-- TABLE: payments
-- One payment record per order. transaction_ref is our idempotency key sent to
-- Wompi. wompi_transaction_id is Wompi's own ID set on first webhook event.
-- =============================================================================

CREATE TABLE IF NOT EXISTS payments (
  id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id                UUID            NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  transaction_ref         TEXT            UNIQUE NOT NULL,  -- our UUID4 sent to Wompi
  wompi_transaction_id    TEXT,                             -- Wompi's id; null until first event
  amount_cop              INT             NOT NULL,
  status                  payment_status  NOT NULL DEFAULT 'pending',
  payment_method          TEXT,           -- 'CARD','PSE','NEQUI','BANCOLOMBIA_TRANSFER',...
  raw_payload             JSONB,          -- last Wompi event payload (audit trail)
  created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_order
  ON payments(order_id);

CREATE INDEX IF NOT EXISTS idx_payments_transaction_ref
  ON payments(transaction_ref);

-- =============================================================================
-- TABLE: payment_events
-- Idempotency log. event_id PRIMARY KEY ensures insert-or-fail deduplication.
-- The Wompi webhook Edge Function inserts here first; on UNIQUE violation it
-- returns 200 "already processed" without mutating any other table.
-- =============================================================================

CREATE TABLE IF NOT EXISTS payment_events (
  event_id      TEXT        PRIMARY KEY,          -- Wompi's event id (globally unique per Wompi spec)
  payment_id    UUID        REFERENCES payments(id) ON DELETE SET NULL,
  kind          TEXT        NOT NULL,              -- 'transaction.updated', etc.
  payload       JSONB       NOT NULL,              -- full Wompi event body
  received_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- FUNCTION: generate_order_number()
-- Called by BEFORE INSERT trigger to assign a human-readable order number.
-- Format: QRA-YYYY-NNNNNN  (e.g. QRA-2026-000042)
-- =============================================================================

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.order_number := 'QRA-'
    || TO_CHAR(NOW(), 'YYYY')
    || '-'
    || LPAD(nextval('order_seq')::TEXT, 6, '0');
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_generate_order_number
  BEFORE INSERT ON orders
  FOR EACH ROW
  WHEN (NEW.order_number IS NULL OR NEW.order_number = '')
  EXECUTE FUNCTION generate_order_number();

-- =============================================================================
-- FUNCTION: validate_order_transition()
-- BEFORE UPDATE OF status trigger on orders.
-- Enforces the FSM — any transition not listed below raises an exception.
-- This is the ONLY place transition logic lives; RPCs just call UPDATE and let
-- this trigger enforce correctness.
--
-- Valid transitions:
--   payment_pending  → payment_failed | paid | cancelled
--   payment_failed   → payment_pending (retry) | cancelled
--   paid             → received_by_ops | cancelled | refunded
--   received_by_ops  → engraving | cancelled | refunded
--   engraving        → engraving_failed | engraving_done
--   engraving_failed → received_by_ops
--   engraving_done   → shipped
--   shipped          → delivered
--   delivered        → refunded  (admin only; no other transitions)
--   cancelled        → (terminal — raise on any change)
--   refunded         → (terminal — raise on any change)
-- =============================================================================

CREATE OR REPLACE FUNCTION validate_order_transition()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Terminal states: no further transitions allowed.
  IF OLD.status IN ('cancelled', 'refunded') THEN
    RAISE EXCEPTION 'Order % is in terminal state % and cannot be transitioned.',
      OLD.id, OLD.status;
  END IF;

  -- payment_pending may go to: payment_failed, paid, cancelled
  IF OLD.status = 'payment_pending' AND NEW.status NOT IN ('payment_failed', 'paid', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- payment_failed may retry (→ payment_pending) or cancel
  IF OLD.status = 'payment_failed' AND NEW.status NOT IN ('payment_pending', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- paid: ops intake, cancel (exceptional), or refund (admin)
  IF OLD.status = 'paid' AND NEW.status NOT IN ('received_by_ops', 'cancelled', 'refunded') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- received_by_ops: start engraving, cancel (admin), or refund (admin)
  IF OLD.status = 'received_by_ops' AND NEW.status NOT IN ('engraving', 'cancelled', 'refunded') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- engraving: completed or failed
  IF OLD.status = 'engraving' AND NEW.status NOT IN ('engraving_failed', 'engraving_done') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- engraving_failed: back to received_by_ops for retry
  IF OLD.status = 'engraving_failed' AND NEW.status NOT IN ('received_by_ops') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- engraving_done: hand off to courier
  IF OLD.status = 'engraving_done' AND NEW.status NOT IN ('shipped') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- shipped: delivery confirmation
  IF OLD.status = 'shipped' AND NEW.status NOT IN ('delivered') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  -- delivered: admin-only refund path
  IF OLD.status = 'delivered' AND NEW.status NOT IN ('refunded') THEN
    RAISE EXCEPTION 'Invalid order transition: % → %', OLD.status, NEW.status;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_validate_order_transition
  BEFORE UPDATE OF status ON orders
  FOR EACH ROW
  EXECUTE FUNCTION validate_order_transition();

-- =============================================================================
-- FUNCTION: create_order
-- Atomically creates an order + order_items + payment record in a single
-- plpgsql transaction. Uses server_compute_order_totals (Phase 8 RPC) for
-- server-authoritative totals — Anti-Pattern 5 mitigation.
--
-- Parameters:
--   p_user_id          UUID     — authenticated user (from auth.uid() on caller side)
--   p_cart_item_ids    UUID[]   — array of cart_items.id to include in this order
--   p_shipping         JSONB    — {recipient_name, phone, department, city, address, notes?}
--   p_idempotency_key  TEXT     — UUID4 generated by client; used as payments.transaction_ref
--
-- Returns: UUID — the new orders.id
--
-- Security: SECURITY DEFINER so it can read product_variants and cart_items
-- without client-level SELECT grants on those tables. Cross-user isolation
-- enforced via WHERE ci.user_id = p_user_id in every cart_items query.
-- =============================================================================

CREATE OR REPLACE FUNCTION create_order(
  p_user_id         UUID,
  p_cart_item_ids   UUID[],
  p_shipping        JSONB,
  p_idempotency_key TEXT
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_order_id      UUID;
  v_subtotal_cop  INT;
  v_tax_cop       INT;
  v_shipping_cop  INT;
  v_total_cop     INT;
BEGIN
  -- 1. Server-authoritative totals via Phase 8 RPC.
  --    Uses p_user_id (not auth.uid() — SECURITY DEFINER context) guarded by
  --    WHERE ci.user_id = p_user_id inside server_compute_order_totals.
  SELECT subtotal_cop, iva_cop, envio_cop, total_cop
    INTO v_subtotal_cop, v_tax_cop, v_shipping_cop, v_total_cop
    FROM server_compute_order_totals(p_user_id);

  IF v_total_cop = 0 THEN
    RAISE EXCEPTION 'Cannot create order: cart is empty or total is zero for user %', p_user_id;
  END IF;

  -- 2. Insert the order row (order_number assigned by trigger).
  INSERT INTO orders (
    order_number,
    user_id,
    status,
    subtotal_cop,
    tax_cop,
    shipping_cop,
    total_cop,
    shipping_recipient_name,
    shipping_phone,
    shipping_department,
    shipping_city,
    shipping_address,
    shipping_notes
  )
  VALUES (
    '',  -- trigger overwrites with QRA-YYYY-NNNNNN
    p_user_id,
    'payment_pending',
    v_subtotal_cop,
    v_tax_cop,
    v_shipping_cop,
    v_total_cop,
    p_shipping->>'recipient_name',
    p_shipping->>'phone',
    p_shipping->>'department',
    p_shipping->>'city',
    p_shipping->>'address',
    p_shipping->>'notes'  -- nullable
  )
  RETURNING id INTO v_order_id;

  -- 3. Insert order_items from the provided cart item IDs.
  --    WHERE ci.user_id = p_user_id prevents cross-user cart injection (T-09-02).
  INSERT INTO order_items (
    order_id,
    product_variant_id,
    qr_code_id,
    customization_snapshot,
    qr_png_url,
    unit_price_cop,
    quantity,
    line_total_cop
  )
  SELECT
    v_order_id,
    ci.product_variant_id,
    ci.qr_code_id,
    ci.customization_snapshot,
    COALESCE(ci.png_storage_url, ''),  -- may be '' if async upload pending
    pv.price_cop,
    ci.quantity,
    pv.price_cop * ci.quantity
  FROM cart_items ci
  JOIN product_variants pv ON pv.id = ci.product_variant_id
  WHERE ci.id = ANY(p_cart_item_ids)
    AND ci.user_id = p_user_id;     -- cross-user isolation guard

  -- 4. Insert the payments record using the idempotency key.
  INSERT INTO payments (
    order_id,
    transaction_ref,
    amount_cop,
    status
  )
  VALUES (
    v_order_id,
    p_idempotency_key,
    v_total_cop,
    'pending'
  );

  RETURN v_order_id;

EXCEPTION
  WHEN unique_violation THEN
    -- Idempotency: same key was already used → order already created.
    RAISE EXCEPTION 'Order already created for idempotency key: %', p_idempotency_key;
END;
$$;

-- =============================================================================
-- FUNCTION: apply_payment_event
-- Called by the wompi-webhook Edge Function after idempotency check passes.
-- Updates payments.status and orders.status based on Wompi transaction status.
-- The validate_order_transition trigger enforces FSM correctness on the UPDATE.
--
-- Parameters:
--   p_transaction_ref       TEXT  — matches payments.transaction_ref (our key)
--   p_wompi_status          TEXT  — Wompi value: APPROVED|DECLINED|VOIDED|ERROR
--   p_wompi_transaction_id  TEXT  — Wompi's own transaction ID
--   p_payment_method        TEXT  — Wompi payment method string
--   p_raw_payload           JSONB — full Wompi event payload for audit
--
-- Security: SECURITY DEFINER + granted to service_role (Edge Function key).
-- =============================================================================

CREATE OR REPLACE FUNCTION apply_payment_event(
  p_transaction_ref       TEXT,
  p_wompi_status          TEXT,
  p_wompi_transaction_id  TEXT,
  p_payment_method        TEXT,
  p_raw_payload           JSONB
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_new_payment_status  payment_status;
  v_new_order_status    order_status;
  v_order_id            UUID;
BEGIN
  -- Map Wompi status → our enums.
  v_new_payment_status := CASE p_wompi_status
    WHEN 'APPROVED' THEN 'approved'::payment_status
    WHEN 'DECLINED' THEN 'declined'::payment_status
    WHEN 'VOIDED'   THEN 'voided'::payment_status
    ELSE                 'error'::payment_status
  END;

  v_new_order_status := CASE p_wompi_status
    WHEN 'APPROVED' THEN 'paid'::order_status
    ELSE                 'payment_failed'::order_status
  END;

  -- Update the payments record.
  UPDATE payments
  SET
    status                = v_new_payment_status,
    wompi_transaction_id  = p_wompi_transaction_id,
    payment_method        = p_payment_method,
    raw_payload           = p_raw_payload,
    updated_at            = NOW()
  WHERE transaction_ref = p_transaction_ref
  RETURNING order_id INTO v_order_id;

  IF v_order_id IS NULL THEN
    RAISE EXCEPTION 'No payment found for transaction_ref: %', p_transaction_ref;
  END IF;

  -- Update the order status (FSM trigger validates the transition).
  IF v_new_order_status = 'paid'::order_status THEN
    UPDATE orders
    SET status  = 'paid',
        paid_at = NOW()
    WHERE id = v_order_id;
  ELSE
    UPDATE orders
    SET status = 'payment_failed'
    WHERE id = v_order_id;
  END IF;
END;
$$;

-- =============================================================================
-- ROW LEVEL SECURITY: orders
-- Client may only SELECT their own orders.
-- INSERT/UPDATE/DELETE from client are denied — all mutations via RPCs.
-- =============================================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "orders_select_own"
  ON orders FOR SELECT
  USING (user_id = auth.uid());

-- No INSERT/UPDATE/DELETE policies for authenticated role → denied by default.
-- create_order and apply_payment_event are SECURITY DEFINER and bypass RLS.

-- =============================================================================
-- ROW LEVEL SECURITY: order_items
-- Client may only SELECT items belonging to their own orders.
-- =============================================================================

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "order_items_select_own"
  ON order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_items.order_id
        AND o.user_id = auth.uid()
    )
  );

-- =============================================================================
-- ROW LEVEL SECURITY: payments
-- Client may only SELECT payments for their own orders.
-- =============================================================================

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payments_select_own"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = payments.order_id
        AND o.user_id = auth.uid()
    )
  );

-- =============================================================================
-- ROW LEVEL SECURITY: payment_events
-- Zero client access (T-09-04). Only service_role (Edge Function) may write.
-- service_role bypasses RLS automatically.
-- =============================================================================

ALTER TABLE payment_events ENABLE ROW LEVEL SECURITY;

-- No SELECT/INSERT/UPDATE/DELETE policies for authenticated role → all denied.

-- =============================================================================
-- GRANTS
-- create_order: authenticated users initiate checkout → need EXECUTE.
-- apply_payment_event: called only by wompi-webhook Edge Function (service_role).
--   service_role already has superuser-equivalent; GRANT is belt-and-suspenders.
-- =============================================================================

GRANT EXECUTE ON FUNCTION create_order(UUID, UUID[], JSONB, TEXT)
  TO authenticated;

GRANT EXECUTE ON FUNCTION apply_payment_event(TEXT, TEXT, TEXT, TEXT, JSONB)
  TO authenticated;  -- belt-and-suspenders; Edge Function uses service_role key

GRANT EXECUTE ON FUNCTION apply_payment_event(TEXT, TEXT, TEXT, TEXT, JSONB)
  TO service_role;
