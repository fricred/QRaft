-- =============================================================================
-- Migration: 20260510000001_notify_on_order_transition.sql
-- Phase 10 Plan 04 — FCM notification pipeline: transition_order RPC +
--                    insert_order_notification helper + apply_payment_event patch
-- Apply    : Supabase Dashboard → SQL Editor
-- Depends  : 20260510000000_notifications_fcm_schema.sql (notifications, user_fcm_tokens)
--            20260505000000_orders_payments_schema.sql   (orders, apply_payment_event)
-- =============================================================================

-- =============================================================================
-- SECTION 1 — Helper: insert_order_notification
-- Inserts a row into notifications for every order FSM transition.
-- Called by both transition_order (operator) and apply_payment_event (Wompi).
-- SECURITY DEFINER: writes to notifications without client INSERT policy.
-- =============================================================================

CREATE OR REPLACE FUNCTION insert_order_notification(
  p_user_id      UUID,
  p_order_id     UUID,
  p_order_number TEXT,
  p_kind         TEXT,
  p_title_es     TEXT,
  p_body_es      TEXT
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO notifications (user_id, order_id, kind, title_es, body_es, data)
  VALUES (
    p_user_id,
    p_order_id,
    p_kind,
    p_title_es,
    p_body_es,
    jsonb_build_object('order_id', p_order_id, 'order_number', p_order_number)
  );
END;
$$;

-- =============================================================================
-- SECTION 2 — transition_order RPC
-- For Phase 11 operator dashboard. Built here so the FSM is complete and
-- testable before Phase 11.
--
-- Parameters:
--   p_order_id   UUID         — target order
--   p_new_status order_status — destination status
--
-- Security:
--   SECURITY DEFINER bypasses RLS for UPDATE on orders.
--   GRANT EXECUTE to service_role ONLY — authenticated client must NEVER call this.
--   The FSM trigger (validate_order_transition) validates transition legality.
-- =============================================================================

CREATE OR REPLACE FUNCTION transition_order(
  p_order_id    UUID,
  p_new_status  order_status
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_order  orders%ROWTYPE;
  v_title  TEXT;
  v_body   TEXT;
  v_kind   TEXT;
BEGIN
  -- Load the order.
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found: %', p_order_id;
  END IF;

  -- Build notification text based on target state (Spanish per app language).
  v_kind  := 'order_' || p_new_status::TEXT;
  v_title := CASE p_new_status
    WHEN 'received_by_ops'  THEN 'Orden recibida'
    WHEN 'engraving'        THEN 'Grabando tu QR'
    WHEN 'engraving_failed' THEN 'Reintentando grabado'
    WHEN 'engraving_done'   THEN 'Grabado completado'
    WHEN 'shipped'          THEN '¡Enviado!'
    WHEN 'delivered'        THEN '¡Entregado!'
    WHEN 'cancelled'        THEN 'Orden cancelada'
    WHEN 'refunded'         THEN 'Reembolso procesado'
    ELSE                         'Estado actualizado'
  END;
  v_body := CASE p_new_status
    WHEN 'received_by_ops'  THEN 'Recibimos tu orden ' || v_order.order_number || '. ¡Empezamos pronto!'
    WHEN 'engraving'        THEN 'Tu orden ' || v_order.order_number || ' está siendo grabada ahora.'
    WHEN 'engraving_failed' THEN 'Hubo un inconveniente. Estamos rehaciendo tu orden ' || v_order.order_number || '.'
    WHEN 'engraving_done'   THEN 'Tu QR está listo. En proceso de envío.'
    WHEN 'shipped'          THEN 'Tu orden ' || v_order.order_number || ' está en camino. Número de guía disponible en la app.'
    WHEN 'delivered'        THEN 'Tu orden ' || v_order.order_number || ' fue entregada. ¡Disfrútala!'
    WHEN 'cancelled'        THEN 'Tu orden ' || v_order.order_number || ' ha sido cancelada.'
    WHEN 'refunded'         THEN 'El reembolso de tu orden ' || v_order.order_number || ' ha sido procesado.'
    ELSE                         'Tu orden ' || v_order.order_number || ' ha cambiado de estado.'
  END;

  -- Update order status (FSM trigger validate_order_transition enforces legality).
  UPDATE orders SET status = p_new_status WHERE id = p_order_id;

  -- Insert notification row (DB Webhook on notifications INSERT → send-fcm Edge Function).
  PERFORM insert_order_notification(
    v_order.user_id,
    p_order_id,
    v_order.order_number,
    v_kind,
    v_title,
    v_body
  );
END;
$$;

-- GRANT: Only service_role (operator dashboard / admin API) may call transition_order.
-- Do NOT grant to authenticated role — clients must never drive the FSM directly.
-- T-10-15 mitigation: elevation of privilege via direct client FSM call is blocked here.
GRANT EXECUTE ON FUNCTION transition_order(UUID, order_status) TO service_role;
GRANT EXECUTE ON FUNCTION insert_order_notification(UUID, UUID, TEXT, TEXT, TEXT, TEXT) TO service_role;

-- =============================================================================
-- SECTION 3 — Patch apply_payment_event
-- Full CREATE OR REPLACE with the original body PLUS notification INSERT on APPROVED.
-- This is idempotent; safe to re-apply over the version in 20260505000000.
--
-- The wompi-webhook Edge Function already calls apply_payment_event RPC.
-- After this patch: APPROVED payment → notifications INSERT → DB Webhook → send-fcm.
-- No changes to wompi-webhook Edge Function needed.
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
  v_user_id             UUID;
  v_order_number        TEXT;
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
    status               = v_new_payment_status,
    wompi_transaction_id = p_wompi_transaction_id,
    payment_method       = p_payment_method,
    raw_payload          = p_raw_payload,
    updated_at           = NOW()
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

    -- Fetch user_id and order_number for notification.
    SELECT user_id, order_number
      INTO v_user_id, v_order_number
      FROM orders
      WHERE id = v_order_id;

    -- Insert payment notification (drives FCM via DB Webhook → send-fcm).
    -- T-10-13: title/body built server-side; no user-supplied text in notification body.
    PERFORM insert_order_notification(
      v_user_id,
      v_order_id,
      v_order_number,
      'payment_approved',
      '¡Pago confirmado!',
      'Tu orden ' || v_order_number || ' ha sido recibida y está en cola de grabado.'
    );
  ELSE
    UPDATE orders
    SET status = 'payment_failed'
    WHERE id = v_order_id;
  END IF;
END;
$$;

-- Re-apply grants (idempotent).
GRANT EXECUTE ON FUNCTION apply_payment_event(TEXT, TEXT, TEXT, TEXT, JSONB)
  TO authenticated;  -- belt-and-suspenders; Edge Function uses service_role key

GRANT EXECUTE ON FUNCTION apply_payment_event(TEXT, TEXT, TEXT, TEXT, JSONB)
  TO service_role;

-- =============================================================================
-- CHECKPOINT (manual, Phase 10 plan 04):
-- After applying this migration, configure Supabase DB Webhook in Dashboard:
--   Table: notifications  |  Events: INSERT
--   HTTP POST to: https://<project-ref>.supabase.co/functions/v1/send-fcm
--   Headers: { "Authorization": "Bearer <service_role_key>" }
--   (Find service_role key in: Supabase Dashboard → Settings → API)
-- =============================================================================
