-- DB Webhook: call send-fcm Edge Function on INSERT into notifications.
-- Uses pg_net extension (available by default in all Supabase projects).

CREATE OR REPLACE FUNCTION public.trigger_send_fcm_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM net.http_post(
    url     := 'https://cnieotneosdkfzboxazw.supabase.co/functions/v1/send-fcm',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ***REMOVED_SECRET***'
    ),
    body    := jsonb_build_object(
      'type',      TG_OP,
      'table',     TG_TABLE_NAME,
      'schema',    TG_TABLE_SCHEMA,
      'record',    row_to_json(NEW)
    )
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER notify_on_order_update
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_send_fcm_notification();
