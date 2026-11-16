-- Dynamic QR hardening, round 2 (re-review):
--  * The "no client delete of dynamic rows" guard is RESTRICTIVE, so no other permissive
--    DELETE policy can bypass it.
--  * Only live dynamic codes (active / paused) can go into a cart or an order: an unpaid,
--    deleted or blocked code would be engraved scanning to a notice page.

CREATE POLICY qr_codes_no_dynamic_delete ON public.qr_codes
  AS RESTRICTIVE FOR DELETE USING (NOT is_dynamic);

CREATE OR REPLACE FUNCTION public.ensure_qr_printable()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.qr_code_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.redirects r
     WHERE r.qr_code_id = NEW.qr_code_id AND r.status NOT IN ('active', 'paused')
  ) THEN
    RAISE EXCEPTION 'qr_not_printable' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_qr_printable() FROM PUBLIC;

DROP TRIGGER IF EXISTS ensure_qr_printable ON public.cart_items;
CREATE TRIGGER ensure_qr_printable
  BEFORE INSERT OR UPDATE OF qr_code_id ON public.cart_items
  FOR EACH ROW EXECUTE FUNCTION public.ensure_qr_printable();

DROP TRIGGER IF EXISTS ensure_qr_printable ON public.order_items;
CREATE TRIGGER ensure_qr_printable
  BEFORE INSERT OR UPDATE OF qr_code_id ON public.order_items
  FOR EACH ROW EXECUTE FUNCTION public.ensure_qr_printable();
