-- Catalog truth pass: only publish what the xTool F1 Ultra can actually produce.
--
-- Background: the seed catalog advertises materials this machine cannot make.
-- Under Colombian Ley 1480/2011 art. 30, "la presentación del producto" is part
-- of the definition of misleading advertising, and the SIC can order a campaign
-- stopped (art. 59.6). Anything unsellable must leave the storefront.
--
-- Machine reality (source: xTool support articles 1476 and 1325):
--   fiber 1064nm  → all metals; color marking on stainless/titanium by oxidation;
--                   cuts brass 0.4mm / stainless 0.3mm / aluminium 0.2mm
--   diode  455nm  → wood, leather, paper, BLACK acrylic (cuts to 12mm), rock/slate
--   embossing     → true 3D relief via depth maps on brass, copper, wood and ROCKS
--   neither       → glass, and cutting stone (stone blanks are bought pre-cut)
--
-- This migration is strictly additive and idempotent. It never DELETEs: rows stay
-- so order_items' ON DELETE RESTRICT keeps working for existing orders. Hiding is
-- done with is_active = false, which the public_read_variants RLS policy already
-- filters on.

-- 1. Glass: the fiber does not mark it and the diode needs marking spray.
--    The market does this with CO2 or sandblasting. Cannot deliver → unpublish.
UPDATE product_variants pv
   SET is_active = false
  FROM materials m
 WHERE pv.material_id = m.id
   AND m.id = 'glass';

-- 2. Temporary tattoos: print + cutting plotter, not a laser process. The seed
--    itself flags laser_compatible = false. Hidden until a supplier is closed or
--    until the stencil variant is validated as diode-cuttable.
UPDATE product_variants
   SET is_active = false
 WHERE material_id = 'tattoo_transfer';

-- 3. Acrylic: the blue diode passes straight through transparent acrylic without
--    being absorbed — it neither cuts nor engraves it. Black/coloured acrylic
--    works well and cuts up to 12mm. Rename so the catalog stops implying clear.
UPDATE materials
   SET display_name_es = 'Acrílico negro',
       display_name_en = 'Black acrylic'
 WHERE id = 'acrylic';

-- 4. Stone stays active on purpose. It is the one material where this machine
--    does something a plain diode competitor cannot: layered depth-map embossing
--    (up to 10 passes / 256 layers) for real 3D relief. See plan phase F.
UPDATE materials
   SET laser_compatible = true
 WHERE id = 'stone';

-- 5. Hygiene: this URL points at a domain that does not exist, so every render of
--    a tattoo card fires a failing network request before falling back to the
--    gradient. Empty string is the documented "no texture" value.
UPDATE materials
   SET texture_url = ''
 WHERE texture_url = 'https://placeholder.qraft.link/tattoo_texture.jpg';
