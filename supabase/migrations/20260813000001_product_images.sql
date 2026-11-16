-- Real product photography for the marketplace.
--
-- Why a table and not a column: today the only image in the catalog is
-- materials.texture_url, which is shared by every product made of that material —
-- the wood texture is identical for the keychain and the plaque. Real photos need
-- product×material granularity, plus a gallery.
--
-- Scope is derived from which FK is set, resolved most-specific-first:
--   variant   → one exact variant (rare: keychain ring vs plain plaque)
--   material  → product + material. This is where ~90% of the content lives.
--   product   → material-agnostic: packaging, scale-in-hand, process shots
--
-- CONTENT RULE (not enforceable in schema, hence the COMMENT): a scope='product'
-- row must NOT show a specific material. If the photo shows wood it belongs to
-- material_id='wood'. This is the line between an honest catalog and misleading
-- advertising under Ley 1480/2011 art. 30.
--
-- Strictly additive and idempotent: never touches product_variants or order_items.

-- Composite unique key required by the coherence FK below.
DO $$
BEGIN
  ALTER TABLE product_variants
    ADD CONSTRAINT product_variants_product_id_id_key UNIQUE (product_id, id);
EXCEPTION
  WHEN duplicate_table THEN NULL;
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS product_images (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Natural key so seeding is idempotent and re-shooting is an UPDATE, not a
  -- duplicate. Convention: '{slug}__{material|all}__{nn}'.
  image_key          TEXT NOT NULL UNIQUE,

  product_id         UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  material_id        TEXT REFERENCES materials(id),
  product_variant_id UUID,

  -- Storage path RELATIVE to the bucket, never an absolute URL. The absolute URL
  -- is built in Flutter with getPublicUrl(). Storing absolute URLs is what left
  -- materials.texture_url pointing at a dead domain, and it also breaks moving
  -- between projects, which have different refs.
  bucket_id          TEXT NOT NULL DEFAULT 'product-images',
  storage_path       TEXT NOT NULL,
  thumb_path         TEXT,

  alt_text_es        TEXT NOT NULL DEFAULT '',
  alt_text_en        TEXT NOT NULL DEFAULT '',
  position           INT  NOT NULL DEFAULT 0,
  is_primary         BOOLEAN NOT NULL DEFAULT false,

  width_px           INT,
  height_px          INT,

  -- Inverted default vs the rest of the catalog, on purpose: it lets the seed be
  -- written before the photos exist (paths are a deterministic contract) and
  -- flipped on with a one-line UPDATE once the files are uploaded.
  is_active          BOOLEAN NOT NULL DEFAULT false,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Bumped on every re-shoot; Flutter appends ?v={epoch} so the CDN and
  -- cached_network_image (which key by URL) do not serve the stale photo.
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  scope TEXT GENERATED ALWAYS AS (
    CASE WHEN product_variant_id IS NOT NULL THEN 'variant'
         WHEN material_id        IS NOT NULL THEN 'material'
         ELSE 'product' END
  ) STORED,

  -- Mirrors isSafeStoragePath() in Dart: relative, no scheme, no traversal.
  CONSTRAINT product_images_path_relative CHECK (
    length(btrim(storage_path)) > 0
    AND storage_path !~ '^[a-zA-Z][a-zA-Z0-9+.-]*://'
    AND storage_path NOT LIKE '/%'
    AND storage_path NOT LIKE '%..%'
  ),
  CONSTRAINT product_images_thumb_relative CHECK (
    thumb_path IS NULL OR (
      thumb_path !~ '^[a-zA-Z][a-zA-Z0-9+.-]*://'
      AND thumb_path NOT LIKE '/%'
      AND thumb_path NOT LIKE '%..%')
  ),

  -- A variant-scoped row carries no material: the variant already implies one.
  CONSTRAINT product_images_scope_exclusive CHECK (
    product_variant_id IS NULL OR material_id IS NULL
  ),

  -- The variant must belong to the product. MATCH SIMPLE means the FK is
  -- satisfied automatically while product_variant_id is NULL.
  CONSTRAINT product_images_variant_belongs_to_product
    FOREIGN KEY (product_id, product_variant_id)
    REFERENCES product_variants (product_id, id) ON DELETE CASCADE
);

COMMENT ON TABLE product_images IS
  'Real product photography. CONTENT RULE: scope=product rows must NOT show a specific material (misleading-advertising risk under Ley 1480/2011 art. 30); if the photo shows wood, set material_id=wood.';
COMMENT ON COLUMN product_images.storage_path IS
  'Path relative to bucket_id. Absolute URL is built in Flutter via getPublicUrl(). Never store absolute URLs (see the placeholder.qraft.link incident in materials.texture_url).';

CREATE INDEX IF NOT EXISTS idx_product_images_scope_lookup
  ON product_images (product_id, material_id, position)
  WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_product_images_variant
  ON product_images (product_variant_id)
  WHERE product_variant_id IS NOT NULL AND is_active;

-- At most one primary per scope bucket.
CREATE UNIQUE INDEX IF NOT EXISTS uq_product_images_one_primary_per_scope
  ON product_images (
    product_id,
    COALESCE(material_id, ''),
    COALESCE(product_variant_id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  WHERE is_primary AND is_active;

-- Same posture as the rest of the catalog: public read, writes only via
-- service_role (migrations / CLI / dashboard).
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_read_product_images" ON product_images;
CREATE POLICY "public_read_product_images"
  ON product_images FOR SELECT USING (is_active = true);

-- Superseded by this table. Left in place (nothing reads it) to avoid a
-- destructive change; documented so nobody wires it up by mistake.
COMMENT ON COLUMN products.hero_image_url IS
  'DEPRECATED (2026-08). Use product_images with scope=product. Not selected from Flutter.';
