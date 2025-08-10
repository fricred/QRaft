-- Add favorites functionality to QR codes
-- This migration adds an is_favorite column to enable favorites feature

-- Add is_favorite column to qr_codes table
ALTER TABLE qr_codes 
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;

-- Create index for favorites queries
CREate INDEX IF NOT EXISTS idx_qr_codes_favorites 
ON qr_codes(user_id, is_favorite) 
WHERE is_favorite = TRUE;

-- Add comment for documentation
COMMENT ON COLUMN qr_codes.is_favorite IS 'Whether this QR code is marked as favorite by the user';

-- Verification query
SELECT 'Favorites column added successfully!' as status,
       column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'qr_codes' AND column_name = 'is_favorite';
