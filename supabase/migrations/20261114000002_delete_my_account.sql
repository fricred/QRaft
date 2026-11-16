-- QRAFT-19 (P2-05): in-app account deletion (Google Play / App Store requirement).
-- Deletes the caller's account and personal data. Orders are kept for accounting
-- (orders.user_id is ON DELETE RESTRICT): in that case the login is anonymized and
-- blocked instead of removed, so no personal data stays attached to it.

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

  -- Personal data in public tables (most also cascade from auth.users; explicit here so
  -- the anonymize path below clears them too).
  DELETE FROM public.qr_codes WHERE user_id::text = v_uid::text;
  DELETE FROM public.scan_history WHERE user_id::text = v_uid::text;
  DELETE FROM public.redirects WHERE owner_id::text = v_uid::text;
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
