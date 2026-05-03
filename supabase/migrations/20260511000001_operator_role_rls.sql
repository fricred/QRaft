-- Migration: 20260511000001_operator_role_rls.sql
-- Purpose: Operator role table, is_operator() security function, and RLS policies
-- Plan: 11-03 (MKT-11)

-- Operator profiles (who can access the operator dashboard)
CREATE TABLE IF NOT EXISTS operator_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  granted_by TEXT  -- email of granting admin
);

ALTER TABLE operator_profiles ENABLE ROW LEVEL SECURITY;

-- Only service_role can manage operator_profiles (all consumer reads/writes blocked)
CREATE POLICY "service_role manages operators" ON operator_profiles
  FOR ALL USING (false) WITH CHECK (false);

-- is_operator(): returns true if current auth.uid() is in operator_profiles
-- SECURITY DEFINER: runs with the function owner's privileges, not the caller's.
-- This ensures auth.uid() is read from the Postgres session context and cannot
-- be spoofed from the client side (T-11-11 accepted).
CREATE OR REPLACE FUNCTION is_operator() RETURNS boolean
  LANGUAGE sql SECURITY DEFINER STABLE
  AS $$ SELECT EXISTS (SELECT 1 FROM operator_profiles WHERE user_id = auth.uid()) $$;

-- Allow operator to read ALL orders (bypasses user_id filter).
-- Applied as a PERMISSIVE additional policy alongside the existing consumer policy.
CREATE POLICY "operator_read_all_orders" ON orders
  FOR SELECT USING (is_operator());

-- Allow operator to read ALL order_items
CREATE POLICY "operator_read_all_order_items" ON order_items
  FOR SELECT USING (is_operator());

-- Allow operator to read ALL shipments (if table exists)
-- Using DO block to gracefully skip if shipments table not yet created
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'shipments'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "operator_read_all_shipments" ON shipments
        FOR SELECT USING (is_operator())
    $policy$;
  END IF;
END
$$;
