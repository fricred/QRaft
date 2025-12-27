-- Migration: Add subscription fields to users table
-- Description: Enables freemium model with Free/Pro plans

-- Add subscription fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_plan TEXT DEFAULT 'free'
  CHECK (subscription_plan IN ('free', 'pro', 'trial'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'active'
  CHECK (subscription_status IN ('active', 'expired', 'cancelled', 'trial'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ;

-- Fields for Phase 2 (payment integration)
ALTER TABLE users ADD COLUMN IF NOT EXISTS payment_provider TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS payment_customer_id TEXT;

-- Create index for subscription queries
CREATE INDEX IF NOT EXISTS idx_users_subscription_plan ON users(subscription_plan);
CREATE INDEX IF NOT EXISTS idx_users_subscription_expires ON users(subscription_expires_at);

-- Function to count user's QR codes
CREATE OR REPLACE FUNCTION get_user_qr_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM qr_codes WHERE user_id = user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_user_qr_count(UUID) TO authenticated;

-- Update existing users to have 'free' plan (already defaulted, but explicit)
UPDATE users SET subscription_plan = 'free' WHERE subscription_plan IS NULL;
UPDATE users SET subscription_status = 'active' WHERE subscription_status IS NULL;
