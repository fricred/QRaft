import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/redirect_supabase_data_source.dart';
import '../../data/repositories/redirect_repository_impl.dart';
import '../../domain/entities/redirect_entity.dart';
import '../../domain/repositories/redirect_repository.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// Raw [SupabaseClient] provider — kept as a simple Provider so tests can
/// override it with a mock client without reaching into the service singleton.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final redirectDataSourceProvider = Provider<RedirectSupabaseDataSource>((ref) {
  return RedirectSupabaseDataSource(ref.watch(supabaseClientProvider));
});

final redirectRepositoryProvider = Provider<RedirectRepository>((ref) {
  return RedirectRepositoryImpl(
    ref.watch(redirectDataSourceProvider),
    ref.watch(supabaseClientProvider),
  );
});

// ---------------------------------------------------------------------------
// Feature providers
// ---------------------------------------------------------------------------

/// Async list of the authenticated user's redirects.
///
/// Auto-disposes so the list is re-fetched whenever the user navigates
/// back to a screen that watches this provider.
final userRedirectsProvider =
    FutureProvider.autoDispose<List<RedirectEntity>>((ref) {
  return ref.watch(redirectRepositoryProvider).getUserRedirects();
});
