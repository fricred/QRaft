-- Enable Realtime for cart_items table
--
-- CartSupabaseDataSource.watchCart streams cart rows via .stream(), which
-- relies on the supabase_realtime publication for INSERT/UPDATE/DELETE events.
-- Without this, the stream only ever holds its initial snapshot: the cart
-- badge and CartScreen show stale (empty) data after adding items.

ALTER PUBLICATION supabase_realtime ADD TABLE cart_items;

-- Note: Realtime respects RLS — users only receive events for their own rows.
