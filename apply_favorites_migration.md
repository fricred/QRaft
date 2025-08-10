# Apply Favorites Migration

To enable the favorites functionality, apply the database migration:

## Option 1: Supabase Dashboard (Recommended)

1. Go to your **Supabase Dashboard** → **SQL Editor**
2. Copy and execute the contents of: `supabase/migrations/20250810000000_add_favorites_column.sql`
3. The migration will add the `is_favorite` column and create the necessary index

## Option 2: Supabase CLI

```bash
echo "YOUR_DB_PASSWORD" | supabase db push
```

## Migration Contents

The migration adds:
- `is_favorite BOOLEAN DEFAULT FALSE` column to `qr_codes` table
- Index on `(user_id, is_favorite)` for optimized favorites queries
- Column documentation comment

## Verification

After applying the migration, you can verify it worked by running:

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'qr_codes' AND column_name = 'is_favorite';
```

Expected result:
- `column_name`: is_favorite
- `data_type`: boolean
- `is_nullable`: YES
- `column_default`: false
