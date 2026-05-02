---
phase: 04-redirect-service-foundation
plan: "01"
subsystem: redirect
tags: [supabase, migration, domain-layer, rls, riverpod, slug-generation]
dependency_graph:
  requires: []
  provides: [redirects-table-ddl, redirect-domain-layer, slug-generator]
  affects: [04-02-edge-function-redirect, 04-03-flutter-destination-editing]
tech_stack:
  added: []
  patterns: [clean-architecture, repository-pattern, equatable-entity, riverpod-providers]
key_files:
  created:
    - supabase/migrations/20260502000000_redirects_table.sql
    - lib/features/redirect/domain/entities/redirect_entity.dart
    - lib/features/redirect/domain/repositories/redirect_repository.dart
    - lib/features/redirect/domain/utils/slug_generator.dart
    - lib/features/redirect/data/datasources/redirect_supabase_data_source.dart
    - lib/features/redirect/data/repositories/redirect_repository_impl.dart
    - lib/features/redirect/presentation/providers/redirect_providers.dart
  modified: []
decisions:
  - "Atomic scan_count increment deferred to plan 04-02 Postgres RPC; v1 uses read-modify-write in RedirectRepositoryImpl.incrementScanCount"
  - "supabaseClientProvider introduced as overridable Provider so tests can inject a mock SupabaseClient without global state"
  - "auto-update trigger (trg_redirects_updated_at) added to migration for server-side updated_at management"
metrics:
  duration: "~7 minutes"
  completed: "2026-05-02T11:58:00Z"
  tasks_completed: 2
  files_created: 7
  files_modified: 0
---

# Phase 4 Plan 01: Redirects Table and Domain Layer Summary

## One-liner

`redirects` Supabase table DDL + RLS + Dart clean-architecture layer (entity, abstract repo, slug generator, Supabase datasource, Riverpod providers) for the `qraft.link/{slug}` redirect infrastructure.

## What Was Built

### Migration SQL (`20260502000000_redirects_table.sql`)

Full DDL for the `redirects` table:

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | gen_random_uuid() |
| slug | TEXT UNIQUE NOT NULL | 6-char a-z0-9 |
| destination_url | TEXT NOT NULL | editable in v1 |
| owner_id | UUID -> auth.users | CASCADE delete |
| scan_count | INTEGER DEFAULT 0 | analytics |
| last_scanned_at | TIMESTAMPTZ | analytics |
| last_country | TEXT | ISO 3166-1 alpha-2 |
| created_at | TIMESTAMPTZ DEFAULT NOW() | |
| updated_at | TIMESTAMPTZ DEFAULT NOW() | auto-updated via trigger |

Indexes: `idx_redirects_slug` (hot path), `idx_redirects_owner`.

RLS policies:
- `public_read_by_slug` — `FOR SELECT USING (true)` — allows unauthenticated Edge Function to resolve slugs
- `owner_insert` — `WITH CHECK (auth.uid() = owner_id)`
- `owner_update` — `USING (auth.uid() = owner_id)`
- `owner_delete` — `USING (auth.uid() = owner_id)`

**IMPORTANT: Migration NOT auto-applied.** Run in Supabase Dashboard → SQL Editor at deployment time.

### Dart Domain Layer

- **`RedirectEntity`** — `Equatable` value object, `fromJson`/`toJson`/`copyWith`.
- **`RedirectRepository`** (abstract) — 6 methods: `createRedirect`, `getRedirectBySlug`, `updateDestinationUrl`, `getUserRedirects`, `incrementScanCount`, `isSlugAvailable`.
- **`SlugGenerator`** — `Random.secure()`, 36-char alphabet (a-z0-9), 6-char output, `generateUntilUnique(isUnique:)` retry loop (max 10 attempts).

### Dart Data Layer

- **`RedirectSupabaseDataSource`** — PostgREST per method. Scan analytics use `updateScanAnalytics()` (read-modify-write) until the plan 04-02 atomic RPC is introduced.
- **`RedirectRepositoryImpl`** — wires datasource; auto-generates slug if `entity.slug.isEmpty` via `SlugGenerator.generateUntilUnique`.

### Riverpod Providers (`redirect_providers.dart`)

| Provider | Type | Purpose |
|---|---|---|
| `supabaseClientProvider` | `Provider<SupabaseClient>` | overridable for tests |
| `redirectDataSourceProvider` | `Provider<RedirectSupabaseDataSource>` | datasource singleton |
| `redirectRepositoryProvider` | `Provider<RedirectRepository>` | repo singleton |
| `userRedirectsProvider` | `FutureProvider.autoDispose<List<RedirectEntity>>` | owner's redirect list |

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written, with one proactive clarification:

**[Rule 2 - Missing Critical Functionality] Atomic scan_count increment deferred**

The plan spec calls for `incrementScanCount` without specifying whether it should be atomic.  A raw `UPDATE scan_count = scan_count + 1` via PostgREST PostgREST (`.rpc()`) requires a Postgres function that does not exist yet.  Plan 04-02 introduces the `increment_redirect_scan(id UUID)` RPC.  To avoid a plan dependency, `incrementScanCount` uses a read-modify-write pattern in `RedirectRepositoryImpl` for v1.  This is documented in both the code and this SUMMARY for plan 04-02 to resolve.

**[Rule 2 - Missing Critical Functionality] `auto-update trigger` added to migration**

The plan SQL snippet did not include an `updated_at` auto-update trigger, but the column exists in the schema spec.  Added `update_redirects_updated_at()` function + `trg_redirects_updated_at` trigger for server-side timestamp management — prevents stale `updated_at` values when rows are modified via Edge Functions or dashboard.

## Manual Deployment Step Required

The migration file `supabase/migrations/20260502000000_redirects_table.sql` must be applied manually:

1. Open Supabase Dashboard → [Project cnieotneosdkfzboxazw]
2. Navigate to SQL Editor
3. Paste the full contents of the migration file
4. Click Run

Until this step is completed, any Dart code that reads from or writes to the `redirects` table will receive a PostgREST `404` error.

## Verification

- `flutter analyze --no-fatal-warnings`: **0 issues**
- Commit: `8122624`
- All 7 files created as specified in plan frontmatter
- No unexpected file deletions

## Known Stubs

None — this is a pure code/SQL plan with no UI rendering.  The `userRedirectsProvider` returns an empty list if `currentUser` is null (correct behavior when unauthenticated).

## Self-Check: PASSED

All created files exist on disk and commit `8122624` is in git history.
