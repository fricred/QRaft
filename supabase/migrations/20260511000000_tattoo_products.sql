-- Migration: 20260511000000_tattoo_products.sql
-- Purpose: Add tattoo_transfer material, tattoo QR product + variants, and tattoo_studio_waitlist table
-- Plan: 11-02 (TAT-01..TAT-04)

-- 1. Insert tattoo_transfer material
INSERT INTO materials (id, display_name_es, display_name_en, texture_url, laser_compatible, notes)
VALUES (
  'tattoo_transfer',
  'Tatuaje Temporal / Stencil',
  'Temporary Tattoo / Stencil',
  'https://placeholder.qraft.link/tattoo_texture.jpg',
  false,
  '{"min_size_mm": 20, "max_logo_pct": 15, "qr_profile": "tattoo_safe"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- 2. Insert tattoo QR product
INSERT INTO products (slug, name_es, name_en, description_es, description_en, is_active)
VALUES (
  'tattoo-qr-transfer',
  'QR Tatuaje Temporal',
  'Temporary Tattoo QR',
  'Lleva tu QR personalizado en la piel. Papel transfer de alta calidad, dura 5-7 días. Perfecto para eventos, festivales y uso personal.',
  'Carry your personalized QR on your skin. High-quality transfer paper, lasts 5-7 days. Perfect for events, festivals and personal use.',
  true
)
ON CONFLICT (slug) DO NOTHING;

-- 3. Insert tattoo product variants (2 sizes)
-- Variant 5x5cm @ 15000 COP
INSERT INTO product_variants (product_id, material_id, size_label, width_mm, height_mm, price_cop, sku, is_active)
SELECT
  p.id,
  'tattoo_transfer',
  '5x5cm',
  50,
  50,
  15000,
  'TAT-QR-50x50',
  true
FROM products p
WHERE p.slug = 'tattoo-qr-transfer'
ON CONFLICT (sku) DO NOTHING;

-- Variant 8x8cm @ 22000 COP
INSERT INTO product_variants (product_id, material_id, size_label, width_mm, height_mm, price_cop, sku, is_active)
SELECT
  p.id,
  'tattoo_transfer',
  '8x8cm',
  80,
  80,
  22000,
  'TAT-QR-80x80',
  true
FROM products p
WHERE p.slug = 'tattoo-qr-transfer'
ON CONFLICT (sku) DO NOTHING;

-- 4. Create tattoo_studio_waitlist table
CREATE TABLE IF NOT EXISTS tattoo_studio_waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  studio_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(email)
);

ALTER TABLE tattoo_studio_waitlist ENABLE ROW LEVEL SECURITY;

-- Anyone can insert (no auth required — unauthenticated CTA)
CREATE POLICY "Anyone can insert waitlist entry" ON tattoo_studio_waitlist
  FOR INSERT WITH CHECK (true);

-- Only service_role can read (blocks all consumer client reads)
CREATE POLICY "Only service_role can read waitlist" ON tattoo_studio_waitlist
  FOR SELECT USING (false);
