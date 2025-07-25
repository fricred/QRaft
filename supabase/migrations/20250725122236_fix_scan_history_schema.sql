-- Fix scan_history table schema for QR Scanner
-- This migration fixes the missing columns that caused the QR scanner to fail

-- Drop the old scan_history table if it exists (backup any important data first)
DROP TABLE IF EXISTS scan_history;

-- Recreate scan_history table with correct schema
CREATE TABLE scan_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    raw_value TEXT NOT NULL,           -- The actual QR code content
    qr_type TEXT NOT NULL,             -- Type: url, text, wifi, email, etc.
    display_value TEXT NOT NULL,       -- Human-readable version
    parsed_data JSONB,                 -- Structured parsed data
    scanned_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_scan_history_user_id ON scan_history(user_id);
CREATE INDEX idx_scan_history_scanned_at ON scan_history(scanned_at DESC);

-- Enable Row Level Security
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own scan history"
    ON scan_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own scan history"
    ON scan_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own scan history"
    ON scan_history FOR DELETE
    USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON scan_history TO authenticated;

-- Add helpful comment
COMMENT ON TABLE scan_history IS 'QR scan history with enhanced schema for Flutter QRaft app';