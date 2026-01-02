-- Enable Realtime for users table
-- This allows the app to receive real-time updates when subscription status changes
-- (e.g., when RevenueCat webhook updates subscription_status to 'expired')

-- Add users table to supabase_realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE users;

-- Note: By default, Supabase Realtime respects RLS policies.
-- The user will only receive updates for their own row.
