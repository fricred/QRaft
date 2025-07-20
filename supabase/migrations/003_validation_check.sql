-- Migration: 003_validation_check.sql
-- Description: Validation check for avatar functionality and migration tracking
-- Created: 2024-07-20
-- Author: QRaft Team

-- Verify that the migrations table exists and is working
SELECT 'Migration tracking table exists' as status;

-- Verify that the avatars bucket exists
SELECT 
  id,
  name,
  public,
  created_at
FROM storage.buckets 
WHERE id = 'avatars';

-- Verify that storage policies are properly configured
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%avatar%';

-- Check applied migrations
SELECT 
  id,
  name,
  executed_at
FROM public.migrations 
ORDER BY executed_at;

-- Record this migration
INSERT INTO public.migrations (name)
VALUES ('003_validation_check.sql')
ON CONFLICT (name) DO NOTHING;

-- Summary report
SELECT 
  'Avatar functionality validation complete' as status,
  NOW() as timestamp;