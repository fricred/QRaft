import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/payments_service.dart';
import '../../../../features/cart/presentation/providers/cart_providers.dart';
import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/shipping_address.dart';

/// Holds the [ShippingAddress] being built on [ShippingScreen].
///
/// Reset to null when the user navigates away from the shipping flow.
final shippingAddressProvider = StateProvider<ShippingAddress?>((ref) => null);

/// Triggers order creation when the user confirms the shipping form.
///
/// Auto-disposed after the screen disposes so a fresh UUID is generated on
/// the next checkout attempt (one transaction per attempt).
///
/// Usage:
/// ```dart
/// final sessionAsync = ref.watch(createOrderProvider(shippingAddress));
/// ```
final createOrderProvider = FutureProvider.autoDispose
    .family<CheckoutSession, ShippingAddress>((ref, address) async {
  final cartItems = await ref.read(cartItemsProvider.future);
  final cartItemIds = cartItems.map((i) => i.id).toList();

  return const PaymentsService().createPaymentIntent(
    cartItemIds: cartItemIds,
    shipping: address,
    idempotencyKey: const Uuid().v4(),
  );
});
