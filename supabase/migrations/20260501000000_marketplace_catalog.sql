-- Phase 7: Marketplace Catalog
-- Price unit: whole COP pesos (INT). E.g. 89000 = $89.000 COP.
-- Wompi requires amountInCents — multiply ×100 at checkout time (Phase 9).

-- Drop and recreate catalog tables to ensure correct schema.
-- These tables contain only seed/catalog data (no user-generated content).
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS materials CASCADE;

-- materials: static reference table (6 supported engraving materials)
CREATE TABLE materials (
  id TEXT PRIMARY KEY,              -- 'wood','acrylic','metal','leather','glass','stone'
  display_name_es TEXT NOT NULL,
  display_name_en TEXT NOT NULL,
  texture_url TEXT NOT NULL DEFAULT '',  -- public Supabase Storage URL; '' until assets uploaded
  laser_compatible BOOLEAN NOT NULL DEFAULT true,
  notes JSONB
);

-- products: base product catalog
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name_es TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description_es TEXT,
  description_en TEXT,
  hero_image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- product_variants: size × material × price combinations
CREATE TABLE product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  material_id TEXT NOT NULL REFERENCES materials(id),
  size_label TEXT NOT NULL,         -- '5x5cm','10x10cm','llavero','placa-grande'
  width_mm INT NOT NULL,
  height_mm INT NOT NULL,
  price_cop INT NOT NULL,           -- whole COP pesos (NOT cents). E.g. 89000 = $89.000 COP.
  sku TEXT UNIQUE,
  stock INT,                        -- NULL = unlimited (made-to-order)
  is_active BOOLEAN NOT NULL DEFAULT true
);

-- RLS: public SELECT only; no INSERT/UPDATE for any role (catalog is read-only from Flutter)
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public_read_materials"
  ON materials FOR SELECT USING (true);

CREATE POLICY "public_read_products"
  ON products FOR SELECT USING (is_active = true);

CREATE POLICY "public_read_variants"
  ON product_variants FOR SELECT USING (is_active = true);

-- Seed: 6 material rows (texture_url left blank until PNGs uploaded to material-textures/ bucket)
INSERT INTO materials (id, display_name_es, display_name_en, texture_url, laser_compatible) VALUES
  ('wood',    'Madera',    'Wood',    '',  true),
  ('acrylic', 'Acrílico',  'Acrylic', '',  true),
  ('metal',   'Metal',     'Metal',   '',  true),
  ('leather', 'Cuero',     'Leather', '',  true),
  ('glass',   'Vidrio',    'Glass',   '',  true),
  ('stone',   'Piedra',    'Stone',   '',  true)
ON CONFLICT (id) DO NOTHING;

-- Seed: sample products + variants for dev/testing
-- 1 product × 6 materials × 2 sizes = 12 variants
INSERT INTO products (id, slug, name_es, name_en, description_es, description_en, is_active) VALUES
  ('00000000-0000-0000-0000-000000000001', 'llavero-qr', 'Llavero QR', 'QR Keychain',
   'Llavero personalizado con tu QR grabado con láser de precisión.',
   'Custom keychain with your QR laser-engraved with precision.',
   true),
  ('00000000-0000-0000-0000-000000000002', 'placa-qr', 'Placa QR', 'QR Plaque',
   'Placa decorativa con tu QR grabado a láser.',
   'Decorative plaque with your QR laser-engraved.',
   true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO product_variants (product_id, material_id, size_label, width_mm, height_mm, price_cop, sku, is_active) VALUES
  -- Llavero QR × each material (50×50mm)
  ('00000000-0000-0000-0000-000000000001', 'wood',    'llavero', 50, 50,  45000, 'LQR-WOD-50', true),
  ('00000000-0000-0000-0000-000000000001', 'acrylic', 'llavero', 50, 50,  38000, 'LQR-ACR-50', true),
  ('00000000-0000-0000-0000-000000000001', 'metal',   'llavero', 50, 50,  65000, 'LQR-MET-50', true),
  ('00000000-0000-0000-0000-000000000001', 'leather', 'llavero', 50, 50,  55000, 'LQR-LEA-50', true),
  ('00000000-0000-0000-0000-000000000001', 'glass',   'llavero', 50, 50,  70000, 'LQR-GLS-50', true),
  ('00000000-0000-0000-0000-000000000001', 'stone',   'llavero', 50, 50,  75000, 'LQR-STN-50', true),
  -- Placa QR × each material (100×100mm)
  ('00000000-0000-0000-0000-000000000002', 'wood',    '10x10cm', 100, 100,  89000, 'PQR-WOD-100', true),
  ('00000000-0000-0000-0000-000000000002', 'acrylic', '10x10cm', 100, 100,  75000, 'PQR-ACR-100', true),
  ('00000000-0000-0000-0000-000000000002', 'metal',   '10x10cm', 100, 100, 120000, 'PQR-MET-100', true),
  ('00000000-0000-0000-0000-000000000002', 'leather', '10x10cm', 100, 100, 105000, 'PQR-LEA-100', true),
  ('00000000-0000-0000-0000-000000000002', 'glass',   '10x10cm', 100, 100, 130000, 'PQR-GLS-100', true),
  ('00000000-0000-0000-0000-000000000002', 'stone',   '10x10cm', 100, 100, 140000, 'PQR-STN-100', true)
ON CONFLICT (sku) DO NOTHING;
