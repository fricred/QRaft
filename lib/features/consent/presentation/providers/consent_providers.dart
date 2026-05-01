import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ump_service.dart';
import '../../domain/entities/consent_state.dart';

/// Singleton service provider.
final umpServiceProvider = Provider<UmpService>((ref) {
  return UmpService();
});

/// One-shot init: triggers requestConsentInfoUpdate. Consume via .when() in UI.
final umpInitProvider = FutureProvider<ConsentState>((ref) async {
  final service = ref.read(umpServiceProvider);
  return service.requestConsentInfoUpdate();
});

/// Current consent state. Reads from service singleton.
final consentStateProvider = Provider<ConsentState>((ref) {
  return ref.watch(umpServiceProvider).state;
});

/// True when UMP has finished resolving (form shown or auto-skipped).
/// BannerAdWidget gates render on this; AdMob init waits for this. (D-04)
final umpConsentReadyProvider = Provider<bool>((ref) {
  return ref.watch(consentStateProvider).isResolved;
});

/// True when personalized ads are allowed (obtained or notRequired).
/// AdRequest reads this: nonPersonalizedAds: !consentGranted. (D-06)
final consentGrantedProvider = Provider<bool>((ref) {
  return ref.watch(consentStateProvider).isPersonalizedAllowed;
});
