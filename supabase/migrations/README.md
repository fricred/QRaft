# Supabase Migrations

This directory contains SQL migration files for the QRaft Supabase database.

## Migration Naming Convention

Migrations follow the format: `{number}_{description}.sql`

- **Number**: 3-digit sequential number (001, 002, 003...)
- **Description**: Brief description in snake_case
- **Example**: `001_initial_setup.sql`, `002_storage_policies.sql`

## Current Migrations

| Migration | Description | Status |
|-----------|-------------|---------|
| `001_initial_setup.sql` | Initial database schema, user profiles, RLS policies | ✅ Applied |
| `002_storage_policies.sql` | Storage bucket and policies for avatars | ✅ Applied |

## How to Apply Migrations

### Method 1: Supabase Dashboard (Recommended)
1. Go to **Supabase Dashboard** → **SQL Editor**
2. Copy and paste the migration content
3. Click **Run** to execute

### Method 2: Supabase CLI (Advanced)
```bash
# Install Supabase CLI
npm install -g @supabase/cli

# Login to Supabase
supabase login

# Apply all pending migrations
supabase db reset --linked
```

## Migration Guidelines

### ✅ Best Practices
- **Idempotent**: Migrations should be safe to run multiple times
- **Backwards Compatible**: Don't break existing functionality
- **Atomic**: Each migration should be a complete unit
- **Documented**: Include clear comments explaining changes

### ❌ Avoid
- Dropping tables without backup
- Removing columns that might have data
- Hard-coding sensitive values
- Breaking existing API contracts

## Migration Template

```sql
-- Migration: {number}_{description}.sql
-- Description: Brief description of what this migration does
-- Created: YYYY-MM-DD
-- Author: Developer Name

-- Your SQL changes here

-- Record this migration
INSERT INTO public.migrations (name)
VALUES ('{number}_{description}.sql')
ON CONFLICT (name) DO NOTHING;
```

## Rollback Strategy

For critical changes, create corresponding rollback migrations:
- `003_add_feature.sql` → `004_rollback_add_feature.sql`

## Testing Migrations

Before applying to production:
1. Test on local Supabase instance
2. Verify in staging environment
3. Create backup of production data
4. Apply during maintenance window

## Migration Status

Check applied migrations:
```sql
SELECT * FROM public.migrations ORDER BY executed_at;
```