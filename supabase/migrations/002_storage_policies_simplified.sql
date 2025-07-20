-- Migration: 002_storage_policies_simplified.sql
-- Description: Create migration tracking and prepare for Storage setup
-- Created: 2024-07-20
-- Author: QRaft Team
-- NOTE: Storage bucket must be created via Supabase Dashboard → Storage

-- Create migration tracking table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.migrations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on migrations table
ALTER TABLE public.migrations ENABLE ROW LEVEL SECURITY;

-- Policy to allow reading migration status (drop first for idempotency)
DROP POLICY IF EXISTS "Allow reading migrations" ON public.migrations;
CREATE POLICY "Allow reading migrations" ON public.migrations
FOR SELECT TO public USING (true);

-- Record this migration
INSERT INTO public.migrations (name)
VALUES ('002_storage_policies_simplified.sql')
ON CONFLICT (name) DO NOTHING;

-- IMPORTANT: Manual steps required in Supabase Dashboard:
-- 1. Go to Storage → Create bucket "avatars" (public: true)
-- 2. The bucket will automatically get the correct RLS policies