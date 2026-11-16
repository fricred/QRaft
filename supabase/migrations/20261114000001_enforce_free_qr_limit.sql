-- QRAFT-10: enforce the free-plan QR limit on the server, not only in the app.
-- Free users can own at most 5 QR codes. Pro (and an active trial) is unlimited.
-- The app maps the 'qr_limit_reached' error to the upgrade sheet.

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
  -- Server-side writers (service role, dashboards, migrations) are not limited.
  IF coalesce(auth.role(), '') NOT IN ('authenticated', 'anon') THEN
    RETURN NEW;
  END IF;

  -- Someone else's user_id: let RLS reject it (don't reveal that user's plan/count).
  IF NEW.user_id::text IS DISTINCT FROM auth.uid()::text THEN
    RETURN NEW;
  END IF;

  -- Serialize concurrent inserts of the same user so two parallel saves can't both pass.
  PERFORM pg_advisory_xact_lock(hashtext('qr_limit:' || NEW.user_id::text));

  SELECT subscription_plan, subscription_status, subscription_expires_at, trial_ends_at
    INTO v_plan, v_status, v_expires, v_trial
    FROM public.users
   WHERE id::text = NEW.user_id::text;

  -- Pro access: an active (or cancelled/billing-issue, still inside the paid period) pro plan,
  -- or a trial that has not ended. Same rule as SubscriptionPlan.hasProAccess, a bit lenient
  -- on cancelled-but-not-expired so a paying user is never blocked by the server.
  IF (v_plan = 'pro'
        AND coalesce(v_status, 'active') IN ('active', 'cancelled', 'billing_issue')
        AND (v_expires IS NULL OR v_expires > now() - interval '3 days'))
     OR (v_plan = 'trial' AND v_trial IS NOT NULL AND v_trial > now()) THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO v_count FROM public.qr_codes WHERE user_id::text = NEW.user_id::text;

  IF v_count >= c_free_limit THEN
    RAISE EXCEPTION 'qr_limit_reached'
      USING ERRCODE = 'P0001',
            DETAIL = format('Free plan allows %s QR codes', c_free_limit),
            HINT = 'upgrade';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_qr_code_limit() FROM PUBLIC;

DROP TRIGGER IF EXISTS enforce_qr_code_limit ON public.qr_codes;
CREATE TRIGGER enforce_qr_code_limit
  BEFORE INSERT ON public.qr_codes
  FOR EACH ROW EXECUTE FUNCTION public.enforce_qr_code_limit();
