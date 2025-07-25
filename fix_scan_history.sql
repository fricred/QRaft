-- Fix scan_history table schema for QR Scanner
DROP TABLE IF EXISTS scan_history;

CREATE TABLE scan_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    raw_value TEXT NOT NULL,
    qr_type TEXT NOT NULL,
    display_value TEXT NOT NULL,
    parsed_data JSONB,
    scanned_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scan_history_user_id ON scan_history(user_id);
CREATE INDEX idx_scan_history_scanned_at ON scan_history(scanned_at DESC);

ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scan history"
    ON scan_history FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own scan history"
    ON scan_history FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own scan history"
    ON scan_history FOR DELETE USING (auth.uid() = user_id);

GRANT ALL ON scan_history TO authenticated;