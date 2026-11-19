-- QRAFT-1: a new user could not save any QR in their first session.
--
-- Root cause: with email confirmation enabled, auth.signUp returns no session, so the
-- client-side insert into public.users runs as anon and is rejected by RLS (42501).
-- qr_codes.user_id references public.users(id), so every later QR insert then fails
-- with a foreign key violation (23503) until the profile is created on the next login.
--
-- Fix: create the profile server-side, in the same transaction as the auth user, with a
-- SECURITY DEFINER trigger. The client no longer has to be authenticated to create it.
--
-- NOTE: public.users.id is TEXT in production but UUID in complete_setup.sql. Inserting
-- NEW.id relies on the uuid -> text assignment cast, and the join compares both as text,
-- so this works with either column type.

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, photo_url, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name'),
    COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture'),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Never block account creation because of the profile row: the client and the
  -- backfill below can recreate it. Surface the problem in the Postgres logs instead.
  RAISE WARNING 'handle_new_auth_user: profile insert failed for %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- Backfill accounts that signed up but never completed a profile insert (e.g. test
-- account B from the QA report, which never managed to save a QR).
INSERT INTO public.users (id, email, display_name, photo_url, created_at, updated_at)
SELECT
  au.id,
  COALESCE(au.email, ''),
  COALESCE(au.raw_user_meta_data ->> 'display_name', au.raw_user_meta_data ->> 'full_name', au.raw_user_meta_data ->> 'name'),
  COALESCE(au.raw_user_meta_data ->> 'avatar_url', au.raw_user_meta_data ->> 'picture'),
  NOW(),
  NOW()
FROM auth.users au
LEFT JOIN public.users pu ON pu.id::text = au.id::text
WHERE pu.id IS NULL;
