-- Fix QR codes table schema to match the application model
-- This migration aligns the database schema with QRCodeModel

DO $$ 
BEGIN
    -- Rename 'content' to 'data' if column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'qr_codes' AND column_name = 'content') THEN
        -- If 'data' column doesn't exist, rename 'content' to 'data'
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'qr_codes' AND column_name = 'data') THEN
            ALTER TABLE qr_codes RENAME COLUMN content TO data;
        END IF;
    END IF;
    
    -- Rename 'qr_data' to 'display_data' if column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'qr_codes' AND column_name = 'qr_data') THEN
        -- If 'display_data' column doesn't exist, rename 'qr_data' to 'display_data'
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'qr_codes' AND column_name = 'display_data') THEN
            ALTER TABLE qr_codes RENAME COLUMN qr_data TO display_data;
        END IF;
    END IF;
    
    -- Rename 'title' to 'name' if column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'qr_codes' AND column_name = 'title') THEN
        -- If 'name' column doesn't exist, rename 'title' to 'name'
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'qr_codes' AND column_name = 'name') THEN
            ALTER TABLE qr_codes RENAME COLUMN title TO name;
        END IF;
    END IF;
    
    -- Add 'data' column if it doesn't exist (fallback)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_codes' AND column_name = 'data') THEN
        ALTER TABLE qr_codes ADD COLUMN data TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Add 'display_data' column if it doesn't exist (fallback)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_codes' AND column_name = 'display_data') THEN
        ALTER TABLE qr_codes ADD COLUMN display_data TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Add 'name' column if it doesn't exist (fallback)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_codes' AND column_name = 'name') THEN
        ALTER TABLE qr_codes ADD COLUMN name TEXT NOT NULL DEFAULT '';
    END IF;
    
    -- Rename 'qr_type' to 'type' if needed for consistency
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'qr_codes' AND column_name = 'qr_type') THEN
        -- If 'type' column doesn't exist, rename 'qr_type' to 'type'
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'qr_codes' AND column_name = 'type') THEN
            ALTER TABLE qr_codes RENAME COLUMN qr_type TO type;
        END IF;
    END IF;
    
    -- Add 'type' column if it doesn't exist (fallback)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_codes' AND column_name = 'type') THEN
        ALTER TABLE qr_codes ADD COLUMN type TEXT NOT NULL DEFAULT 'url';
    END IF;
    
    -- Update customization column to include all fields
    ALTER TABLE qr_codes ALTER COLUMN customization SET DEFAULT '{
        "foreground_color": 4278190080,
        "background_color": 4294967295,
        "eye_color": 4278190080,
        "size": 200.0,
        "error_correction_level": 1,
        "logo_path": null,
        "has_logo": false,
        "eye_shape": 0,
        "data_shape": 0,
        "rounded_corners": false,
        "logo_size": 40.0
    }'::jsonb;
    
END $$;

-- Update indexes to use correct column names
DROP INDEX IF EXISTS idx_qr_codes_qr_type;
CREATE INDEX IF NOT EXISTS idx_qr_codes_type ON qr_codes(type);

-- Verify final schema (for debugging)
-- This will show in the migration logs what columns exist
DO $$
DECLARE
    col_name TEXT;
BEGIN
    RAISE NOTICE 'QR Codes table columns after migration:';
    FOR col_name IN 
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'qr_codes' 
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE 'Column: %', col_name;
    END LOOP;
END $$;