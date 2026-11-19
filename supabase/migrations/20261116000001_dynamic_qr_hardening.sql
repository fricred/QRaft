-- Dynamic QR hardening (code review of 20261116000000).
--  1. A dynamic QR row can't be turned into a free static one (data/type/user locked) and
--     at most 3 unpaid reservations per user exist at a time.
--  2. A purchase activates the code the user was paying for: the code whose checkout
--     started last, not the oldest pending one (webhooks usually beat the app's claim).
--  3. Dynamic QR rows can't be deleted from the client (that left the code live); the
--     owner deletes through dynamic_qr_revoke, which also removes the library row.
--  4. Refunds and purchase linking are serialized (no refund slipping in between).

-- 1 ------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_qr_is_dynamic()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF coalesce(auth.role(), '') IN ('authenticated', 'anon') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.is_dynamic := false;
    ELSE
      NEW.is_dynamic := OLD.is_dynamic;
      IF OLD.is_dynamic THEN
        -- The printed link and the counted owner never change from the client;
        -- name and design (customization) stay editable.
        NEW.data := OLD.data;
        NEW.type := OLD.type;
        NEW.user_id := OLD.user_id;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

ALTER TABLE public.redirects ADD COLUMN IF NOT EXISTS checkout_started_at timestamptz;

CREATE OR REPLACE FUNCTION public.dynamic_qr_reserve(
  p_user uuid, p_name text, p_customization jsonb, p_content_type text, p_content jsonb, p_display text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_slug text;
  v_qr uuid;
  v_redirect uuid;
  v_pending integer;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext('dynamic_qr:' || p_user::text));
  SELECT count(*) INTO v_pending FROM public.redirects
   WHERE owner_id = p_user AND status = 'pending_payment';
  IF v_pending >= 3 THEN
    RAISE EXCEPTION 'too_many_pending' USING ERRCODE = 'P0001';
  END IF;

  v_slug := public.next_redirect_slug();
  INSERT INTO public.qr_codes (user_id, type, data, display_data, name, customization, is_dynamic)
  VALUES (p_user, p_content_type, 'https://scanqraft.app/' || v_slug, coalesce(p_display, ''),
          p_name, coalesce(p_customization, '{}'::jsonb), true)
  RETURNING id INTO v_qr;

  INSERT INTO public.redirects (slug, owner_id, qr_code_id, status, content_type, content,
                                destination_url, content_updated_at, checkout_started_at)
  VALUES (v_slug, p_user, v_qr, 'pending_payment', p_content_type, p_content,
          CASE WHEN p_content_type = 'url' THEN p_content->>'payload' END, now(), clock_timestamp())
  RETURNING id INTO v_redirect;

  RETURN jsonb_build_object('redirect_id', v_redirect, 'qr_code_id', v_qr, 'slug', v_slug);
END;
$$;

-- 2 ------------------------------------------------------------------------
-- The app calls this right before opening the store sheet for a pending code.
CREATE OR REPLACE FUNCTION public.dynamic_qr_begin_checkout(p_user uuid, p_redirect uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.redirects SET checkout_started_at = clock_timestamp()
   WHERE id = p_redirect AND owner_id = p_user AND status = 'pending_payment';
$$;

CREATE OR REPLACE FUNCTION public.dynamic_qr_apply_purchase(
  p_user uuid, p_txn text, p_product text, p_purchased_at timestamptz, p_redirect uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_purchase public.dynamic_qr_purchases;
  v_target uuid;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext('dynamic_qr:' || p_user::text));

  INSERT INTO public.dynamic_qr_purchases (user_id, store_transaction_id, product_id, purchased_at)
  VALUES (p_user, p_txn, p_product, p_purchased_at)
  ON CONFLICT (store_transaction_id) DO NOTHING;

  -- Row lock: a concurrent refund of this purchase waits for us (and vice versa).
  SELECT * INTO v_purchase FROM public.dynamic_qr_purchases WHERE store_transaction_id = p_txn FOR UPDATE;
  IF v_purchase.user_id IS DISTINCT FROM p_user THEN
    RAISE EXCEPTION 'purchase_belongs_to_other_user' USING ERRCODE = '42501';
  END IF;
  IF v_purchase.status <> 'owned' THEN
    RETURN jsonb_build_object('state', 'refunded', 'redirect_id', v_purchase.redirect_id);
  END IF;
  IF v_purchase.redirect_id IS NOT NULL THEN
    RETURN jsonb_build_object('state', 'active', 'redirect_id', v_purchase.redirect_id);
  END IF;

  -- The named code if it is still payable, else the code whose checkout started last.
  SELECT r.id INTO v_target
    FROM public.redirects r
   WHERE r.owner_id = p_user AND r.status = 'pending_payment'
     AND NOT EXISTS (SELECT 1 FROM public.dynamic_qr_purchases dp WHERE dp.redirect_id = r.id)
   ORDER BY (r.id = p_redirect) DESC NULLS LAST, r.checkout_started_at DESC NULLS LAST, r.created_at DESC
   LIMIT 1;

  IF v_target IS NULL THEN
    RETURN jsonb_build_object('state', 'credit', 'redirect_id', NULL);
  END IF;

  UPDATE public.dynamic_qr_purchases SET redirect_id = v_target WHERE id = v_purchase.id;
  UPDATE public.redirects SET status = 'active', updated_at = now() WHERE id = v_target;
  RETURN jsonb_build_object('state', 'active', 'redirect_id', v_target);
END;
$$;

-- 4 ------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.dynamic_qr_refund(p_txn text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_purchase public.dynamic_qr_purchases;
BEGIN
  SELECT * INTO v_purchase FROM public.dynamic_qr_purchases WHERE store_transaction_id = p_txn FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('redirect_id', NULL);
  END IF;
  UPDATE public.dynamic_qr_purchases SET status = 'refunded' WHERE id = v_purchase.id;
  IF v_purchase.redirect_id IS NOT NULL THEN
    UPDATE public.redirects SET status = 'revoked', revoked_at = now(), updated_at = now()
     WHERE id = v_purchase.redirect_id AND status <> 'blocked';
  END IF;
  RETURN jsonb_build_object('redirect_id', v_purchase.redirect_id);
END;
$$;

-- 3 ------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can delete own QR codes" ON public.qr_codes;
DROP POLICY IF EXISTS "qr_codes_delete_own" ON public.qr_codes;
CREATE POLICY "qr_codes_delete_own" ON public.qr_codes
  FOR DELETE USING (user_id = (auth.uid())::text AND NOT is_dynamic);

CREATE OR REPLACE FUNCTION public.dynamic_qr_revoke(p_user uuid, p_redirect uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_qr uuid;
BEGIN
  SELECT qr_code_id INTO v_qr FROM public.redirects WHERE id = p_redirect AND owner_id = p_user FOR UPDATE;
  IF NOT FOUND THEN
    RETURN;
  END IF;
  UPDATE public.redirects
     SET status = CASE WHEN status = 'blocked' THEN status ELSE 'revoked' END,
         revoked_at = now(), content = NULL, destination_url = NULL, qr_code_id = NULL, updated_at = now()
   WHERE id = p_redirect;
  DELETE FROM public.redirect_history WHERE redirect_id = p_redirect;
  IF v_qr IS NOT NULL THEN
    DELETE FROM public.qr_codes WHERE id = v_qr AND user_id = p_user::text;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.dynamic_qr_begin_checkout(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dynamic_qr_begin_checkout(uuid, uuid) TO service_role;
REVOKE ALL ON FUNCTION public.dynamic_qr_reserve(uuid, text, jsonb, text, jsonb, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dynamic_qr_reserve(uuid, text, jsonb, text, jsonb, text) TO service_role;
REVOKE ALL ON FUNCTION public.dynamic_qr_apply_purchase(uuid, text, text, timestamptz, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dynamic_qr_apply_purchase(uuid, text, text, timestamptz, uuid) TO service_role;
REVOKE ALL ON FUNCTION public.dynamic_qr_refund(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dynamic_qr_refund(text) TO service_role;
REVOKE ALL ON FUNCTION public.dynamic_qr_revoke(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.dynamic_qr_revoke(uuid, uuid) TO service_role;
