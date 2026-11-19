-- Storage bucket for product photography.
--
-- Declared here rather than clicked in the dashboard, which is how `avatars` and
-- `order-assets` came to exist: unversioned drift that cannot be reproduced on a
-- fresh project.
--
-- Public, not signed: these are marketing assets with no per-user authorisation,
-- and signed URLs would rotate every hour, guaranteeing a cache miss in
-- cached_network_image on every catalog visit. Public also lets Supabase's CDN
-- cache them.
--
-- Path convention (fixed before any photo is taken):
--   {product_slug}/{material_id}/{nn}.webp        1600x1600
--   {product_slug}/{material_id}/{nn}_thumb.webp   600x600
--   {product_slug}/_all/{nn}.webp                 scope=product

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('product-images', 'product-images', true, 5242880,
        ARRAY['image/webp', 'image/jpeg', 'image/png'])
ON CONFLICT (id) DO UPDATE
  SET public             = EXCLUDED.public,
      file_size_limit    = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- No SELECT policy is needed: public buckets are served from
-- /storage/v1/object/public/ without going through RLS.
-- No write policy either, so uploads stay service_role-only (CLI or dashboard),
-- mirroring the read-only posture of the catalog tables.
