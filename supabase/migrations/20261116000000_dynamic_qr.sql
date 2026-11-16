-- Paid dynamic QR codes (US$9.99 one-time, Google Play consumable `qraft_dynamic_qr`).
--
-- A dynamic QR prints https://scanqraft.app/<slug>; what it shows (content_type + content)
-- can change later. The server is the only source of truth for its state:
--   pending_payment → active ⇄ paused → revoked   (blocked = abuse)
-- Clients only READ their rows. Every write goes through the `dynamic-qr` edge function
-- (service role) which calls the dynamic_qr_* functions below. Slugs are never released:
-- deleting a code revokes it (the public page answers 410) so a printed code can never
-- start pointing at somebody else's content.

-- ---------------------------------------------------------------------------
-- redirects: content, status, ownership that survives account deletion
-- ---------------------------------------------------------------------------
ALTER TABLE public.redirects
  ADD COLUMN IF NOT EXISTS content_type text,
  ADD COLUMN IF NOT EXISTS content jsonb,
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'pending_payment',
  ADD COLUMN IF NOT EXISTS content_updated_at timestamptz,
  ADD COLUMN IF NOT EXISTS paused_at timestamptz,
  ADD COLUMN IF NOT EXISTS revoked_at timestamptz;

ALTER TABLE public.redirects ALTER COLUMN destination_url DROP NOT NULL;

-- Rows minted before this migration were plain URL redirects that already worked.
UPDATE public.redirects
   SET status = 'active',
       content_type = 'url',
       content = jsonb_build_object('payload', destination_url),
       content_updated_at = coalesce(updated_at, created_at)
 WHERE content_type IS NULL;

ALTER TABLE public.redirects
  DROP CONSTRAINT IF EXISTS redirects_status_check,
  ADD CONSTRAINT redirects_status_check
    CHECK (status IN ('pending_payment', 'active', 'paused', 'revoked', 'blocked')),
  DROP CONSTRAINT IF EXISTS redirects_content_type_check,
  ADD CONSTRAINT redirects_content_type_check
    CHECK (content_type IS NULL OR content_type IN ('url', 'text', 'vcard', 'vevent', 'geo', 'wifi', 'email'));

-- Keep the redirect (and its slug) when the owner deletes their account.
ALTER TABLE public.redirects DROP CONSTRAINT IF EXISTS redirects_owner_id_fkey;
ALTER TABLE public.redirects
  ADD CONSTRAINT redirects_owner_id_fkey
  FOREIGN KEY (owner_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- The UNIQUE constraint on slug already provides the lookup index.
DROP INDEX IF EXISTS public.idx_redirects_slug;
CREATE INDEX IF NOT EXISTS idx_redirects_owner_status ON public.redirects(owner_id, status);

-- ---------------------------------------------------------------------------
-- qr_codes.is_dynamic: paid codes don't count toward the free limit
-- ---------------------------------------------------------------------------
ALTER TABLE public.qr_codes ADD COLUMN IF NOT EXISTS is_dynamic boolean NOT NULL DEFAULT false;

UPDATE public.qr_codes q SET is_dynamic = true
 WHERE EXISTS (SELECT 1 FROM public.redirects r WHERE r.qr_code_id = q.id);

-- Clients may not flip is_dynamic themselves (it would bypass the free limit).
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
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_qr_is_dynamic ON public.qr_codes;
CREATE TRIGGER protect_qr_is_dynamic
  BEFORE INSERT OR UPDATE ON public.qr_codes
  FOR EACH ROW EXECUTE FUNCTION public.protect_qr_is_dynamic();

-- Same function as 20261114000001, counting only static codes.
CREATE OR REPLACE FUNCTION public.enforce_qr_code_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan    text;
  v_status  text;
  v_expires timestamptz;
  v_trial   timestamptz;
  v_count   integer;
  c_free_limit constant integer := 5;
BEGIN
  IF coalesce(auth.role(), '') NOT IN ('authenticated', 'anon') THEN
    RETURN NEW;
  END IF;
  IF NEW.user_id::text IS DISTINCT FROM auth.uid()::text THEN
    RETURN NEW;
  END IF;

  PERFORM pg_advisory_xact_lock(hashtext('qr_limit:' || NEW.user_id::text));

  SELECT subscription_plan, subscription_status, subscription_expires_at, trial_ends_at
    INTO v_plan, v_status, v_expires, v_trial
    FROM public.users
   WHERE id::text = NEW.user_id::text;

  IF (v_plan = 'pro'
        AND coalesce(v_status, 'active') IN ('active', 'cancelled', 'billing_issue')
        AND (v_expires IS NULL OR v_expires > now() - interval '3 days'))
     OR (v_plan = 'trial' AND v_trial IS NOT NULL AND v_trial > now()) THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO v_count FROM public.qr_codes
   WHERE user_id::text = NEW.user_id::text AND NOT is_dynamic;

  IF v_count >= c_free_limit THEN
    RAISE EXCEPTION 'qr_limit_reached'
      USING ERRCODE = 'P0001',
            DETAIL = format('Free plan allows %s QR codes', c_free_limit),
            HINT = 'upgrade';
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- History, daily scans, purchases ledger
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.redirect_history (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  redirect_id  uuid NOT NULL REFERENCES public.redirects(id) ON DELETE CASCADE,
  content_type text NOT NULL,
  content      jsonb NOT NULL,
  changed_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_redirect_history_redirect ON public.redirect_history(redirect_id, changed_at DESC);

CREATE TABLE IF NOT EXISTS public.redirect_scan_daily (
  redirect_id uuid NOT NULL REFERENCES public.redirects(id) ON DELETE CASCADE,
  day         date NOT NULL,
  scans       integer NOT NULL DEFAULT 0,
  PRIMARY KEY (redirect_id, day)
);

CREATE TABLE IF NOT EXISTS public.dynamic_qr_purchases (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  store_transaction_id text NOT NULL UNIQUE,
  product_id           text NOT NULL,
  redirect_id          uuid UNIQUE REFERENCES public.redirects(id) ON DELETE SET NULL,
  status               text NOT NULL DEFAULT 'owned' CHECK (status IN ('owned', 'refunded')),
  purchased_at         timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_dynamic_qr_purchases_user ON public.dynamic_qr_purchases(user_id);

-- ---------------------------------------------------------------------------
-- RLS: owners read, nobody writes from the client
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "public_read_by_slug" ON public.redirects;
DROP POLICY IF EXISTS "owner_insert" ON public.redirects;
DROP POLICY IF EXISTS "owner_update" ON public.redirects;
DROP POLICY IF EXISTS "owner_delete" ON public.redirects;
DROP POLICY IF EXISTS "owner_read" ON public.redirects;
CREATE POLICY "owner_read" ON public.redirects
  FOR SELECT TO authenticated USING (auth.uid() = owner_id);

ALTER TABLE public.redirect_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "owner_read" ON public.redirect_history;
CREATE POLICY "owner_read" ON public.redirect_history
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.redirects r WHERE r.id = redirect_id AND r.owner_id = auth.uid()));

ALTER TABLE public.redirect_scan_daily ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "owner_read" ON public.redirect_scan_daily;
CREATE POLICY "owner_read" ON public.redirect_scan_daily
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM public.redirects r WHERE r.id = redirect_id AND r.owner_id = auth.uid()));

ALTER TABLE public.dynamic_qr_purchases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "owner_read" ON public.dynamic_qr_purchases;
CREATE POLICY "owner_read" ON public.dynamic_qr_purchases
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

REVOKE INSERT, UPDATE, DELETE ON public.redirects, public.redirect_history,
  public.redirect_scan_daily, public.dynamic_qr_purchases FROM anon, authenticated;

-- ---------------------------------------------------------------------------
-- Server-side operations (service role only; called by the dynamic-qr edge function)
-- ---------------------------------------------------------------------------

-- 8 chars from an alphabet without look-alikes (no 0/o/1/l/i): ~1.1e12 combinations.
CREATE OR REPLACE FUNCTION public.next_redirect_slug()
RETURNS text
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  c_alphabet constant text := 'abcdefghjkmnpqrstuvwxyz23456789';
  v_slug text;
BEGIN
  FOR attempt IN 1..20 LOOP
    v_slug := '';
    FOR i IN 1..8 LOOP
      v_slug := v_slug || substr(c_alphabet, 1 + floor(random() * length(c_alphabet))::int, 1);
    END LOOP;
    IF NOT EXISTS (SELECT 1 FROM public.redirects WHERE slug = v_slug) THEN
      RETURN v_slug;
    END IF;
  END LOOP;
  RAISE EXCEPTION 'slug_exhausted';
END;
$$;

-- Creates the QR (counted as dynamic) and its pending redirect in one transaction.
CREATE OR REPLACE FUNCTION public.dynamic_qr_reserve(
  p_user uuid, p_name text, p_customization jsonb, p_content_type text, p_content jsonb, p_display text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_slug text := public.next_redirect_slug();
  v_qr uuid;
  v_redirect uuid;
BEGIN
  INSERT INTO public.qr_codes (user_id, type, data, display_data, name, customization, is_dynamic)
  VALUES (p_user, p_content_type, 'https://scanqraft.app/' || v_slug, coalesce(p_display, ''),
          p_name, coalesce(p_customization, '{}'::jsonb), true)
  RETURNING id INTO v_qr;

  INSERT INTO public.redirects (slug, owner_id, qr_code_id, status, content_type, content,
                                destination_url, content_updated_at)
  VALUES (v_slug, p_user, v_qr, 'pending_payment', p_content_type, p_content,
          CASE WHEN p_content_type = 'url' THEN p_content->>'payload' END, now())
  RETURNING id INTO v_redirect;

  RETURN jsonb_build_object('redirect_id', v_redirect, 'qr_code_id', v_qr, 'slug', v_slug);
END;
$$;

-- Records a store purchase once and links it to a pending code of that user:
-- p_redirect when given (the code the app just bought), else the oldest pending one.
-- Idempotent on store_transaction_id. Returns the purchase state.
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

  SELECT * INTO v_purchase FROM public.dynamic_qr_purchases WHERE store_transaction_id = p_txn;
  IF v_purchase.user_id IS DISTINCT FROM p_user THEN
    RAISE EXCEPTION 'purchase_belongs_to_other_user' USING ERRCODE = '42501';
  END IF;
  IF v_purchase.status <> 'owned' THEN
    RETURN jsonb_build_object('state', 'refunded', 'redirect_id', v_purchase.redirect_id);
  END IF;
  IF v_purchase.redirect_id IS NOT NULL THEN
    RETURN jsonb_build_object('state', 'active', 'redirect_id', v_purchase.redirect_id);
  END IF;

  SELECT r.id INTO v_target
    FROM public.redirects r
   WHERE r.owner_id = p_user AND r.status = 'pending_payment'
     AND (p_redirect IS NULL OR r.id = p_redirect)
     AND NOT EXISTS (SELECT 1 FROM public.dynamic_qr_purchases dp WHERE dp.redirect_id = r.id)
   ORDER BY (r.id = p_redirect) DESC NULLS LAST, r.created_at
   LIMIT 1;

  IF v_target IS NULL AND p_redirect IS NOT NULL THEN
    -- The named code is gone or already paid: fall back to any pending code.
    SELECT r.id INTO v_target
      FROM public.redirects r
     WHERE r.owner_id = p_user AND r.status = 'pending_payment'
       AND NOT EXISTS (SELECT 1 FROM public.dynamic_qr_purchases dp WHERE dp.redirect_id = r.id)
     ORDER BY r.created_at LIMIT 1;
  END IF;

  IF v_target IS NULL THEN
    RETURN jsonb_build_object('state', 'credit', 'redirect_id', NULL);
  END IF;

  UPDATE public.dynamic_qr_purchases SET redirect_id = v_target WHERE id = v_purchase.id;
  UPDATE public.redirects SET status = 'active', updated_at = now() WHERE id = v_target;
  RETURN jsonb_build_object('state', 'active', 'redirect_id', v_target);
END;
$$;

-- Assigns an unused paid credit of the user to one of their pending codes.
CREATE OR REPLACE FUNCTION public.dynamic_qr_use_credit(p_user uuid, p_redirect uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_txn text;
BEGIN
  SELECT store_transaction_id INTO v_txn FROM public.dynamic_qr_purchases
   WHERE user_id = p_user AND status = 'owned' AND redirect_id IS NULL
   ORDER BY created_at LIMIT 1;
  IF v_txn IS NULL THEN
    RETURN jsonb_build_object('state', 'no_credit');
  END IF;
  RETURN public.dynamic_qr_apply_purchase(p_user, v_txn, 'qraft_dynamic_qr', NULL, p_redirect);
END;
$$;

-- Store refund / chargeback: the purchase stops counting and its code is revoked.
CREATE OR REPLACE FUNCTION public.dynamic_qr_refund(p_txn text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_redirect uuid;
BEGIN
  UPDATE public.dynamic_qr_purchases SET status = 'refunded'
   WHERE store_transaction_id = p_txn
   RETURNING redirect_id INTO v_redirect;
  IF v_redirect IS NOT NULL THEN
    UPDATE public.redirects SET status = 'revoked', revoked_at = now(), updated_at = now()
     WHERE id = v_redirect AND status <> 'blocked';
  END IF;
  RETURN jsonb_build_object('redirect_id', v_redirect);
END;
$$;

-- Owner changes what the code shows (validated by the edge function first).
CREATE OR REPLACE FUNCTION public.dynamic_qr_set_content(
  p_user uuid, p_redirect uuid, p_content_type text, p_content jsonb, p_display text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.redirects;
BEGIN
  SELECT * INTO v_row FROM public.redirects WHERE id = p_redirect AND owner_id = p_user FOR UPDATE;
  IF NOT FOUND OR v_row.status IN ('revoked', 'blocked') THEN
    RAISE EXCEPTION 'redirect_not_editable' USING ERRCODE = 'P0002';
  END IF;

  IF v_row.content_type IS NOT NULL AND v_row.content IS NOT NULL THEN
    INSERT INTO public.redirect_history (redirect_id, content_type, content, changed_at)
    VALUES (v_row.id, v_row.content_type, v_row.content, coalesce(v_row.content_updated_at, now()));
  END IF;

  UPDATE public.redirects
     SET content_type = p_content_type,
         content = p_content,
         destination_url = CASE WHEN p_content_type = 'url' THEN p_content->>'payload' END,
         content_updated_at = now(),
         updated_at = now()
   WHERE id = p_redirect;

  IF v_row.qr_code_id IS NOT NULL THEN
    UPDATE public.qr_codes SET type = p_content_type, display_data = coalesce(p_display, display_data),
                               updated_at = now()
     WHERE id = v_row.qr_code_id;
  END IF;

  RETURN jsonb_build_object('redirect_id', p_redirect, 'content_type', p_content_type);
END;
$$;

CREATE OR REPLACE FUNCTION public.dynamic_qr_set_paused(p_user uuid, p_redirect uuid, p_paused boolean)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status text;
BEGIN
  UPDATE public.redirects
     SET status = CASE WHEN p_paused THEN 'paused' ELSE 'active' END,
         paused_at = CASE WHEN p_paused THEN now() END,
         updated_at = now()
   WHERE id = p_redirect AND owner_id = p_user AND status IN ('active', 'paused')
  RETURNING status INTO v_status;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'redirect_not_pausable' USING ERRCODE = 'P0002';
  END IF;
  RETURN v_status;
END;
$$;

-- Owner deletes a code: content is dropped, the slug stays reserved (public page → 410).
CREATE OR REPLACE FUNCTION public.dynamic_qr_revoke(p_user uuid, p_redirect uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.redirects
     SET status = 'revoked', revoked_at = now(), content = NULL, destination_url = NULL, updated_at = now()
   WHERE id = p_redirect AND owner_id = p_user AND status <> 'blocked';
  DELETE FROM public.redirect_history WHERE redirect_id = p_redirect
    AND EXISTS (SELECT 1 FROM public.redirects r WHERE r.id = p_redirect AND r.owner_id = p_user);
END;
$$;

-- Public scan: atomic counters, only for active codes.
CREATE OR REPLACE FUNCTION public.record_redirect_scan(p_redirect uuid, p_country text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.redirects
     SET scan_count = scan_count + 1,
         last_scanned_at = now(),
         last_country = coalesce(p_country, last_country)
   WHERE id = p_redirect AND status = 'active';
  IF FOUND THEN
    INSERT INTO public.redirect_scan_daily (redirect_id, day, scans)
    VALUES (p_redirect, (now() AT TIME ZONE 'utc')::date, 1)
    ON CONFLICT (redirect_id, day) DO UPDATE SET scans = public.redirect_scan_daily.scans + 1;
  END IF;
END;
$$;

DO $$
DECLARE
  fn text;
BEGIN
  FOREACH fn IN ARRAY ARRAY[
    'public.next_redirect_slug()',
    'public.dynamic_qr_reserve(uuid, text, jsonb, text, jsonb, text)',
    'public.dynamic_qr_apply_purchase(uuid, text, text, timestamptz, uuid)',
    'public.dynamic_qr_use_credit(uuid, uuid)',
    'public.dynamic_qr_refund(text)',
    'public.dynamic_qr_set_content(uuid, uuid, text, jsonb, text)',
    'public.dynamic_qr_set_paused(uuid, uuid, boolean)',
    'public.dynamic_qr_revoke(uuid, uuid)',
    'public.record_redirect_scan(uuid, text)'
  ] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', fn);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', fn);
  END LOOP;
END;
$$;

-- ---------------------------------------------------------------------------
-- Account deletion: revoke dynamic codes instead of deleting them (slug never reused)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_has_orders boolean;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;

  DELETE FROM public.redirect_history h USING public.redirects r
   WHERE h.redirect_id = r.id AND r.owner_id::text = v_uid::text;
  UPDATE public.redirects
     SET status = CASE WHEN status = 'blocked' THEN status ELSE 'revoked' END,
         revoked_at = coalesce(revoked_at, now()),
         content = NULL, destination_url = NULL, qr_code_id = NULL, owner_id = NULL, updated_at = now()
   WHERE owner_id::text = v_uid::text;

  DELETE FROM public.qr_codes WHERE user_id::text = v_uid::text;
  DELETE FROM public.scan_history WHERE user_id::text = v_uid::text;
  DELETE FROM public.cart_items WHERE user_id::text = v_uid::text;
  DELETE FROM public.user_fcm_tokens WHERE user_id::text = v_uid::text;
  DELETE FROM public.notifications WHERE user_id::text = v_uid::text;
  DELETE FROM public.users WHERE id::text = v_uid::text;

  SELECT EXISTS (SELECT 1 FROM public.orders WHERE user_id::text = v_uid::text)
    INTO v_has_orders;

  IF v_has_orders THEN
    UPDATE auth.users
       SET email = 'deleted-' || v_uid::text || '@deleted.invalid',
           phone = NULL,
           encrypted_password = '',
           raw_user_meta_data = '{}'::jsonb,
           banned_until = 'infinity',
           updated_at = now()
     WHERE id = v_uid;
    DELETE FROM auth.identities WHERE user_id = v_uid;
    DELETE FROM auth.sessions WHERE user_id = v_uid;
    RETURN 'anonymized';
  END IF;

  DELETE FROM auth.users WHERE id = v_uid;
  RETURN 'deleted';
END;
$$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
