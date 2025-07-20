-- 🚀 QRAFT - COMPLETE SUPABASE SETUP
-- Execute this file in Supabase Dashboard > SQL Editor
-- This will create all tables and RLS policies needed for QRaft app

-- =============================================================================
-- 1. CREATE TABLES
-- =============================================================================

-- Users table (main profile data)
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    display_name TEXT,
    photo_url TEXT,
    phone_number TEXT,
    bio TEXT,
    location TEXT,
    website TEXT,
    company TEXT,
    job_title TEXT,
    preferences JSONB DEFAULT '{}',
    statistics JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- QR Codes table
CREATE TABLE IF NOT EXISTS qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    qr_type TEXT NOT NULL,
    content TEXT NOT NULL,
    qr_data TEXT NOT NULL,
    title TEXT,
    description TEXT,
    customization JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Scan History table
CREATE TABLE IF NOT EXISTS scan_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    qr_type TEXT NOT NULL,
    content TEXT NOT NULL,
    scanned_data TEXT NOT NULL,
    scanned_at TIMESTAMPTZ DEFAULT NOW()
);

-- Templates table
CREATE TABLE IF NOT EXISTS templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    template_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products table (marketplace)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    material TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    total_amount DECIMAL(10,2) NOT NULL,
    shipping_address JSONB,
    customization JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order Items table
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID,
    qr_code_id UUID,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 2. DROP ALL EXISTING POLICIES (CLEAN SLATE)
-- =============================================================================

-- Users table policies
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_insert_own" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "users_delete_own" ON users;
DROP POLICY IF EXISTS "users_public_read" ON users;
DROP POLICY IF EXISTS "users_authenticated_insert" ON users;
DROP POLICY IF EXISTS "users_authenticated_update" ON users;
DROP POLICY IF EXISTS "users_insert_authenticated" ON users;
DROP POLICY IF EXISTS "firebase_auth_insert" ON users;
DROP POLICY IF EXISTS "firebase_auth_select" ON users;
DROP POLICY IF EXISTS "firebase_auth_update" ON users;
DROP POLICY IF EXISTS "firebase_users_can_insert_profile" ON users;
DROP POLICY IF EXISTS "firebase_users_read_own_data" ON users;
DROP POLICY IF EXISTS "firebase_users_update_own_data" ON users;
DROP POLICY IF EXISTS "firebase_users_delete_own_data" ON users;

-- QR Codes policies
DROP POLICY IF EXISTS "qr_codes_select_own" ON qr_codes;
DROP POLICY IF EXISTS "qr_codes_insert_own" ON qr_codes;
DROP POLICY IF EXISTS "qr_codes_update_own" ON qr_codes;
DROP POLICY IF EXISTS "qr_codes_delete_own" ON qr_codes;

-- Other tables
DROP POLICY IF EXISTS "scan_history_select_own" ON scan_history;
DROP POLICY IF EXISTS "scan_history_insert_own" ON scan_history;
DROP POLICY IF EXISTS "orders_select_own" ON orders;
DROP POLICY IF EXISTS "orders_insert_own" ON orders;
DROP POLICY IF EXISTS "order_items_select_own" ON order_items;
DROP POLICY IF EXISTS "templates_public_read" ON templates;
DROP POLICY IF EXISTS "products_public_read" ON products;

-- =============================================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 4. CREATE RLS POLICIES FOR SUPABASE NATIVE AUTH
-- =============================================================================

-- USERS TABLE POLICIES
CREATE POLICY "users_select_own" ON users
  FOR SELECT TO authenticated
  USING (id = auth.uid()::text);

CREATE POLICY "users_insert_own" ON users
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid()::text);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE TO authenticated
  USING (id = auth.uid()::text)
  WITH CHECK (id = auth.uid()::text);

CREATE POLICY "users_delete_own" ON users
  FOR DELETE TO authenticated
  USING (id = auth.uid()::text);

-- QR CODES TABLE POLICIES
CREATE POLICY "qr_codes_select_own" ON qr_codes
  FOR SELECT TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "qr_codes_insert_own" ON qr_codes
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "qr_codes_update_own" ON qr_codes
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "qr_codes_delete_own" ON qr_codes
  FOR DELETE TO authenticated
  USING (user_id = auth.uid()::text);

-- SCAN HISTORY TABLE POLICIES
CREATE POLICY "scan_history_select_own" ON scan_history
  FOR SELECT TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "scan_history_insert_own" ON scan_history
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

-- ORDERS TABLE POLICIES
CREATE POLICY "orders_select_own" ON orders
  FOR SELECT TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "orders_insert_own" ON orders
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

-- ORDER ITEMS TABLE POLICIES (access through orders)
CREATE POLICY "order_items_select_own" ON order_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders 
      WHERE orders.id = order_items.order_id 
      AND orders.user_id = auth.uid()::text
    )
  );

-- TEMPLATES TABLE POLICIES (public read)
CREATE POLICY "templates_public_read" ON templates
  FOR SELECT TO authenticated, anon
  USING (is_active = true);

-- PRODUCTS TABLE POLICIES (public read)
CREATE POLICY "products_public_read" ON products
  FOR SELECT TO authenticated, anon
  USING (is_active = true);

-- =============================================================================
-- 5. GRANT NECESSARY PERMISSIONS
-- =============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON qr_codes TO authenticated;
GRANT SELECT, INSERT ON scan_history TO authenticated;
GRANT SELECT, INSERT ON orders TO authenticated;
GRANT SELECT ON order_items TO authenticated;
GRANT SELECT ON templates TO authenticated, anon;
GRANT SELECT ON products TO authenticated, anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- =============================================================================
-- 6. CREATE INDEXES FOR PERFORMANCE
-- =============================================================================

-- User lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- QR Codes lookups
CREATE INDEX IF NOT EXISTS idx_qr_codes_user_id ON qr_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_created_at ON qr_codes(created_at DESC);

-- Scan history lookups
CREATE INDEX IF NOT EXISTS idx_scan_history_user_id ON scan_history(user_id);
CREATE INDEX IF NOT EXISTS idx_scan_history_scanned_at ON scan_history(scanned_at DESC);

-- Orders lookups
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Products and templates
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_templates_active ON templates(is_active, sort_order);

-- =============================================================================
-- 7. INSERT SAMPLE DATA (OPTIONAL)
-- =============================================================================

-- Sample templates for QR codes
INSERT INTO templates (name, description, template_data, sort_order) VALUES
('Business Card', 'Professional business card QR template', '{"style": "business", "colors": ["#1A73E8", "#00FF88"]}', 1),
('WiFi Connection', 'Share WiFi credentials easily', '{"style": "wifi", "colors": ["#FF6B6B", "#4ECDC4"]}', 2),
('Contact Info', 'Personal contact information', '{"style": "contact", "colors": ["#9C27B0", "#E91E63"]}', 3),
('Website Link', 'Direct link to your website', '{"style": "url", "colors": ["#FF9800", "#FFC107"]}', 4),
('Social Media', 'Links to social profiles', '{"style": "social", "colors": ["#2196F3", "#00BCD4"]}', 5)
ON CONFLICT DO NOTHING;

-- Sample products for marketplace
INSERT INTO products (name, description, price, material, sort_order) VALUES
('Wooden QR Plaque', 'Laser-engraved QR code on premium oak wood', 29.99, 'Oak Wood', 1),
('Acrylic QR Stand', 'Clear acrylic QR code display stand', 19.99, 'Clear Acrylic', 2),
('Metal QR Tag', 'Durable stainless steel QR code tag', 39.99, 'Stainless Steel', 3),
('Leather QR Keychain', 'Premium leather keychain with QR code', 24.99, 'Genuine Leather', 4),
('Glass QR Coaster', 'Elegant glass coaster with QR code', 34.99, 'Tempered Glass', 5),
('Stone QR Marker', 'Natural stone QR code garden marker', 44.99, 'Natural Stone', 6)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 8. VERIFICATION QUERIES
-- =============================================================================

-- Verify tables were created
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'qr_codes', 'scan_history', 'templates', 'products', 'orders', 'order_items')
ORDER BY table_name;

-- Verify RLS policies
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Verify indexes
SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- Test auth function
SELECT 
  auth.uid() as current_user_id,
  auth.role() as current_role;

-- =============================================================================
-- ✅ SETUP COMPLETE!
-- =============================================================================

SELECT '🚀 QRaft Supabase setup completed successfully!' as status,
       'Tables created, RLS policies applied, indexes added, sample data inserted' as details;