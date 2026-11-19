import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../auth/data/providers/supabase_auth_provider.dart';
import '../../subscription/domain/entities/purchase_error.dart';
import '../../subscription/presentation/providers/purchase_providers.dart';
import '../data/dynamic_qr_repository.dart';
import 'dq_ui.dart';

enum DqPayOutcome { active, pending, cancelled, failed, unavailable }

/// The localized store price of one dynamic QR ("US$9.99", "$39.900"…), or null.
final dynamicQrPackageProvider = FutureProvider.autoDispose<Package?>((ref) async {
  final ds = ref.watch(revenueCatDataSourceProvider);
  try {
    return await ds.getDynamicQrPackage();
  } catch (_) {
    return null;
  }
});

/// Pays for the pending code [redirectId]: an unused paid credit first (e.g. a purchase
/// whose code was deleted before activation), else a store purchase that the server then
/// links to this code. Pending store payments stay `pending_payment`; the RevenueCat
/// webhook activates them when the money arrives.
Future<DqPayOutcome> payForDynamicQr(BuildContext context, WidgetRef ref, String redirectId) async {
  final repo = ref.read(dynamicQrRepositoryProvider);
  final container = ProviderScope.containerOf(context, listen: false);

  try {
    if (await repo.unusedCredits() > 0 && await repo.useCredit(redirectId)) return DqPayOutcome.active;
  } catch (e) {
    debugPrint('dynamic QR credit check failed: $e');
  }

  final userId = ref.read(supabaseAuthProvider).currentUser?.id;
  if (!await ensureRevenueCatReady(container, userId)) return DqPayOutcome.unavailable;

  final ds = ref.read(revenueCatDataSourceProvider);
  final package = await ds.getDynamicQrPackage();
  if (package == null) return DqPayOutcome.unavailable;

  // Tell the server which code this purchase is for before the store sheet opens: the
  // webhook usually arrives before the app's claim and must pick this code.
  try {
    await repo.beginCheckout(redirectId);
  } catch (e) {
    debugPrint('dynamic QR begin checkout failed: $e');
    return DqPayOutcome.failed;
  }

  String? transactionId;
  try {
    transactionId = await ds.purchaseDynamicQr(package);
  } on PurchaseError catch (e) {
    if (e.type == PurchaseErrorType.cancelled) return DqPayOutcome.cancelled;
    if (e.type != PurchaseErrorType.pending) return DqPayOutcome.failed;
    // Pending: the store took the order; nothing to claim until it confirms.
    return DqPayOutcome.pending;
  } catch (e) {
    debugPrint('dynamic QR purchase failed: $e');
    return DqPayOutcome.failed;
  }

  // RevenueCat may need a moment to list the new purchase: retry the claim briefly.
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final status = await repo.claim(redirectId, transactionId: transactionId);
      if (status == DynamicQrStatus.active) return DqPayOutcome.active;
    } catch (e) {
      debugPrint('dynamic QR claim failed: $e');
    }
    await Future<void>.delayed(Duration(seconds: 2 + attempt * 2));
  }
  // Paid but not linked yet: the webhook (or "Restaurar compras") finishes it.
  return DqPayOutcome.pending;
}
