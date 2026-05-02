---
phase: 04-redirect-service-foundation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - supabase/migrations/20260502000000_redirects_table.sql
  - lib/features/redirect/domain/entities/redirect_entity.dart
  - lib/features/redirect/domain/repositories/redirect_repository.dart
  - lib/features/redirect/data/repositories/redirect_repository_impl.dart
  - lib/features/redirect/data/datasources/redirect_supabase_data_source.dart
autonomous: true
requirements:
  - RDR-01
  - RDR-02
  - RDR-03
  - RDR-04
must_haves:
  truths:
    - "`redirects` table exists in Supabase with columns: id (UUID PK), slug (TEXT UNIQUE NOT NULL), destination_url (TEXT NOT NULL), owner_id (UUID REFERENCES auth.users), scan_count (INT DEFAULT 0), last_scanned_at (TIMESTAMPTZ), last_country (TEXT), created_at (TIMESTAMPTZ DEFAULT NOW()), updated_at (TIMESTAMPTZ DEFAULT NOW())"
    - "RLS policies: authenticated users can SELECT/UPDATE/DELETE their own rows (owner_id = auth.uid()); INSERT requires auth; SELECT on slug is public for the redirect service to resolve"
    - "`RedirectEntity` Dart class exists with all table columns, fromJson/toJson"
    - "`RedirectRepository` interface with methods: createRedirect, getRedirectBySlug, updateDestinationUrl, getUserRedirects, incrementScanCount"
    - "`flutter analyze --no-fatal-warnings` exits 0"
  artifacts:
    - path: "supabase/migrations/20260502000000_redirects_table.sql"
      provides: "Redirects table DDL + RLS"
      contains: "CREATE TABLE redirects"
    - path: "lib/features/redirect/domain/entities/redirect_entity.dart"
      provides: "Dart entity for redirect records"
      contains: "RedirectEntity"
---

# Plan 04-01: Redirects Table and Domain Layer

## Objective
Create the `redirects` Supabase table + RLS policies + Dart domain/data layer. This is the foundation for the `qraft.link/{slug}` redirect infrastructure.

## Context
- Supabase project: `cnieotneosdkfzboxazw`
- The `redirects` table doesn't exist yet (no prior migration)
- All engraved QRs will encode `qraft.link/{slug}` URLs — architectural anchor from PROJECT.md
- Free destination editing in v1 (no monetization friction per decision log)
- Slug generation: 6-char alphanumeric, unique

## Tasks

### Task 1 — Create migration SQL and domain layer

Write `supabase/migrations/20260502000000_redirects_table.sql`:
```sql
CREATE TABLE redirects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  destination_url TEXT NOT NULL,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  scan_count INTEGER DEFAULT 0,
  last_scanned_at TIMESTAMPTZ,
  last_country TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast slug lookups (the hot path)
CREATE INDEX idx_redirects_slug ON redirects(slug);
CREATE INDEX idx_redirects_owner ON redirects(owner_id);

-- RLS
ALTER TABLE redirects ENABLE ROW LEVEL SECURITY;

-- Public read for slug resolution (redirect service)
CREATE POLICY "public_read_by_slug" ON redirects
  FOR SELECT USING (true);

-- Owner write
CREATE POLICY "owner_insert" ON redirects
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "owner_update" ON redirects
  FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "owner_delete" ON redirects
  FOR DELETE USING (auth.uid() = owner_id);
```

Create Dart domain layer following auth/ pattern:
- `lib/features/redirect/domain/entities/redirect_entity.dart` — RedirectEntity with fromJson/toJson
- `lib/features/redirect/domain/repositories/redirect_repository.dart` — abstract interface
- `lib/features/redirect/data/datasources/redirect_supabase_data_source.dart` — Supabase impl
- `lib/features/redirect/data/repositories/redirect_repository_impl.dart` — wires datasource

Slug generation helper: `lib/features/redirect/domain/utils/slug_generator.dart` — generates 6-char alphanumeric slug (a-z0-9), retries on collision.

Riverpod providers: `lib/features/redirect/presentation/providers/redirect_providers.dart`

### Task 2 — Verify and document

- `flutter analyze --no-fatal-warnings` = 0 issues
- Note: migration SQL needs to be applied manually via Supabase Dashboard → SQL Editor (user action required at deployment time). Write the SQL file; document the manual step in SUMMARY.md.
- Commit atomically, create SUMMARY.md, update STATE/ROADMAP
