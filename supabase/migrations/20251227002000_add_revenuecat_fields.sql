-- Migration: Add RevenueCat purchase tracking fields
-- Description: Extends subscription fields for RevenueCat IAP integration

-- Add RevenueCat-specific fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS revenuecat_customer_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_product_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_period_type TEXT
  CHECK (subscription_period_type IS NULL OR subscription_period_type IN ('monthly', 'annual', 'lifetime'));
ALTER TABLE users ADD COLUMN IF NOT EXISTS original_purchase_date TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMPTZ;

-- Update subscription_status constraint to include billing_issue
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_subscription_status_check;
ALTER TABLE users ADD CONSTRAINT users_subscription_status_check
  CHECK (subscription_status IN ('active', 'expired', 'cancelled', 'trial', 'billing_issue'));

-- Create index for RevenueCat customer lookup
CREATE INDEX IF NOT EXISTS idx_users_revenuecat_customer ON users(revenuecat_customer_id);

-- Optional: Rename payment columns for clarity (keep old for backwards compat)
-- These were added in previous migration as payment_provider and payment_customer_id
-- We'll use revenuecat_customer_id as the primary field going forward
