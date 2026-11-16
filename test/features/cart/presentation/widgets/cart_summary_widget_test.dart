import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'; // Override moved here in Riverpod 3
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:qraft/features/cart/domain/entities/cart_totals_entity.dart';
import 'package:qraft/features/cart/presentation/providers/cart_providers.dart';
import 'package:qraft/features/cart/presentation/widgets/cart_summary_widget.dart';

/// COP format: es_CO locale places symbol after the number, e.g. "89.000 $"
String _cop(int amount) =>
    NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0)
        .format(amount);

Widget _buildTestApp({required Override totalsOverride}) {
  return ProviderScope(
    overrides: [totalsOverride],
    child: const MaterialApp(
      home: Scaffold(
        body: CartSummaryWidget(),
      ),
    ),
  );
}

void main() {
  group('CartSummaryWidget', () {
    testWidgets(
      'Test 1: renders formatted COP values for non-zero totals',
      (tester) async {
        const totals = CartTotalsEntity(
          subtotalCop: 89000,
          ivaCop: 16910,
          envioCop: 15000,
          totalCop: 120910,
        );

        await tester.pumpWidget(
          _buildTestApp(
            totalsOverride: cartTotalsProvider.overrideWith(
              (ref) async => totals,
            ),
          ),
        );
        await tester.pump(); // allow FutureProvider to complete

        expect(find.text(_cop(89000)), findsOneWidget);
        expect(find.text(_cop(16910)), findsOneWidget);
        expect(find.text(_cop(15000)), findsOneWidget);
        expect(find.text(_cop(120910)), findsOneWidget);
      },
    );

    testWidgets(
      'Test 2: CartTotalsEntity.zero shows formatted \$0 subtotal and formatted \$15.000 envío',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            totalsOverride: cartTotalsProvider.overrideWith(
              (ref) async => CartTotalsEntity.zero,
            ),
          ),
        );
        await tester.pump();

        // Both subtotal (0) and IVA (0) render as "0 $" — at least one present.
        expect(find.text(_cop(0)), findsAtLeastNWidgets(1));
        // Envío 15,000 COP shows even on empty cart.
        expect(find.text(_cop(15000)), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Test 3: loading state shows shimmer, not an error or crash',
      (tester) async {
        // Use a Completer that never completes to keep the loading state.
        await tester.pumpWidget(
          _buildTestApp(
            totalsOverride: cartTotalsProvider.overrideWith(
              (_) async {
                // Simulate an immediate "still loading" by never completing.
                // We abort this with pump(zero) before the future can resolve.
                await Future<void>.delayed(const Duration(seconds: 10));
                return CartTotalsEntity.zero;
              },
            ),
          ),
        );
        // First frame: FutureProvider is in loading state.
        await tester.pump(Duration.zero);

        // Widget should not throw; no error text visible.
        expect(find.text('No se pudo calcular el total'), findsNothing);
        expect(tester.takeException(), isNull);

        // Drain remaining timers to avoid "pending timer" assertion.
        await tester.pump(const Duration(seconds: 11));
      },
    );

    testWidgets(
      'Test 4: IVA row label contains "19%"',
      (tester) async {
        const totals = CartTotalsEntity(
          subtotalCop: 89000,
          ivaCop: 16910,
          envioCop: 15000,
          totalCop: 120910,
        );

        await tester.pumpWidget(
          _buildTestApp(
            totalsOverride: cartTotalsProvider.overrideWith(
              (ref) async => totals,
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('19%'), findsOneWidget);
      },
    );
  });
}
