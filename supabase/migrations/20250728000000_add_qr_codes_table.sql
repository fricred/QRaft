-- QR Codes table for storing generated QR codes
-- Note: Table might already exist, so we use CREATE TABLE IF NOT EXISTS and ALTER TABLE for safety
CREATE TABLE IF NOT EXISTS qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    qr_type TEXT NOT NULL, -- 'vcard', 'url', 'wifi', 'text', 'email', 'geo'
    content TEXT NOT NULL, -- The actual QR code content
    qr_data TEXT NOT NULL, -- Generated QR data
    title TEXT,
    description TEXT,
    customization JSONB DEFAULT '{
        "foreground_color": 0,
        "background_color": 16777215,
        "size": 200.0,
        "error_correction_level": 1,
        "logo_path": null,
        "has_logo": false
    }'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns if they don't exist (for existing tables)
DO $$ 
BEGIN
    -- Add title column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_codes' AND column_name = 'title') THEN
        ALTER TABLE qr_codes ADD COLUMN title TEXT;
    END IF;
    
    -- Add description column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'qr_codes' AND column_name = 'description') THEN
        ALTER TABLE qr_codes ADD COLUMN description TEXT;
    END IF;
    
    -- Update customization column default if needed
    ALTER TABLE qr_codes ALTER COLUMN customization SET DEFAULT '{
        "foreground_color": 0,
        "background_color": 16777215,
        "size": 200.0,
        "error_correction_level": 1,
        "logo_path": null,
        "has_logo": false
    }'::jsonb;
END $$;

-- Create indexes for better performance (using existing column names)
CREATE INDEX IF NOT EXISTS idx_qr_codes_user_id ON qr_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_qr_type ON qr_codes(qr_type);
CREATE INDEX IF NOT EXISTS idx_qr_codes_created_at ON qr_codes(created_at DESC);

-- Enable Row Level Security
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Users can insert their own QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Users can update their own QR codes" ON qr_codes;
DROP POLICY IF EXISTS "Users can delete their own QR codes" ON qr_codes;

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON qr_codes TO authenticated;

-- Note: RLS policies will be set up separately if needed
-- The complete setup file handles all policies consistently

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_qr_codes_updated_at ON qr_codes;
CREATE TRIGGER update_qr_codes_updated_at
    BEFORE UPDATE ON qr_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();