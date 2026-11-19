import 'package:equatable/equatable.dart';

/// Server-authoritative cart totals in whole COP pesos.
///
/// Populated exclusively from the [server_compute_order_totals()] Postgres RPC.
/// NEVER computed client-side — Anti-Pattern 5 mitigation (ARCHITECTURE.md):
/// Wompi accepts whatever amount the merchant sends, so client-side total
/// computation would allow a tampered build to pay an arbitrary amount.
class CartTotalsEntity extends Equatable {
  /// Sum of (price_cop × quantity) for all cart items.
  final int subtotalCop;

  /// Colombian IVA at 19% of subtotalCop, rounded to the nearest whole peso.
  final int ivaCop;

  /// Flat shipping rate in whole COP pesos.
  /// Phase 9 may replace with address-based calculation.
  final int envioCop;

  /// subtotalCop + ivaCop + envioCop.
  final int totalCop;

  const CartTotalsEntity({
    required this.subtotalCop,
    required this.ivaCop,
    required this.envioCop,
    required this.totalCop,
  });

  /// Construct from a Postgres RPC result row (snake_case keys).
  factory CartTotalsEntity.fromRpcRow(Map<String, dynamic> row) =>
      CartTotalsEntity(
        subtotalCop: row['subtotal_cop'] as int,
        ivaCop: row['iva_cop'] as int,
        envioCop: row['envio_cop'] as int,
        totalCop: row['total_cop'] as int,
      );

  /// Sentinel value for empty cart or unauthenticated state.
  /// Still includes the flat envío so the UI always shows shipping cost.
  static const CartTotalsEntity zero = CartTotalsEntity(
    subtotalCop: 0,
    ivaCop: 0,
    envioCop: 15000,
    totalCop: 15000,
  );

  @override
  List<Object?> get props => [subtotalCop, ivaCop, envioCop, totalCop];
}
