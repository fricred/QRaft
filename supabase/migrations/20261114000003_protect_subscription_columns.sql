-- QRAFT-10 follow-up: the plan columns of public.users are written only by the server
-- (revenuecat-webhook, service role). A signed-in user can still edit their own profile
-- fields, but any change they make to the plan columns is ignored (kept as before /
-- reset to defaults on insert). Without this, a free user could PATCH their own row to
-- 'pro' and skip the free QR limit (enforce_qr_code_limit trusts these columns).

CREATE OR REPLACE FUNCTION public.protect_subscription_columns()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only end users are restricted; service role / postgres (webhook, dashboard) are not.
  IF coalesce(auth.role(), '') NOT IN ('authenticated', 'anon') THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    -- A row created by the client (e.g. after deleting it) always starts free.
    NEW.subscription_plan := 'free';
    NEW.subscription_status := 'active';
    NEW.subscription_expires_at := NULL;
    NEW.subscription_product_id := NULL;
    NEW.subscription_period_type := NULL;
    NEW.trial_started_at := NULL;
    NEW.trial_ends_at := NULL;
    NEW.original_purchase_date := NULL;
    NEW.revenuecat_customer_id := NULL;
    NEW.last_verified_at := NULL;
  ELSE
    -- Silently keep the server's values (the app's RevenueCat sync must not error out).
    NEW.subscription_plan := OLD.subscription_plan;
    NEW.subscription_status := OLD.subscription_status;
    NEW.subscription_expires_at := OLD.subscription_expires_at;
    NEW.subscription_product_id := OLD.subscription_product_id;
    NEW.subscription_period_type := OLD.subscription_period_type;
    NEW.trial_started_at := OLD.trial_started_at;
    NEW.trial_ends_at := OLD.trial_ends_at;
    NEW.original_purchase_date := OLD.original_purchase_date;
    NEW.revenuecat_customer_id := OLD.revenuecat_customer_id;
    NEW.last_verified_at := OLD.last_verified_at;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.protect_subscription_columns() FROM PUBLIC;

DROP TRIGGER IF EXISTS protect_subscription_columns ON public.users;
CREATE TRIGGER protect_subscription_columns
  BEFORE INSERT OR UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.protect_subscription_columns();
