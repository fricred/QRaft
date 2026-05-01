import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/consent_state.dart';
import '../providers/consent_providers.dart';
import '../screens/ump_consent_screen.dart';

/// Wrapper widget that gates `child` on UMP consent readiness (D-04).
///
/// - While `umpInitProvider` is loading: renders a Carden Pro splash-style
///   centered progress indicator.
/// - On error: fail-open and render `child` so the app does not deadlock on
///   a UMP SDK error.
/// - On data: if state is resolved (notRequired/obtained/denied) renders
///   `child`; else renders [UmpConsentScreen] which triggers Google's UMP form.
///
/// Mounted by `lib/main.dart` after the splash completes; downstream consumers
/// (banner ads, rewarded ads) gate on `umpConsentReadyProvider` independently.
class UmpGate extends ConsumerWidget {
  final Widget child;
  const UmpGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(umpInitProvider);
    final ready = ref.watch(umpConsentReadyProvider);

    if (ready) return child;

    return initAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) {
        // Fail-open: do not block the app on UMP errors. Show child.
        debugPrint('UmpGate error, failing open: $e');
        return child;
      },
      data: (state) {
        if (state.isResolved) return child;
        return const UmpConsentScreen();
      },
    );
  }
}
