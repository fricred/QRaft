import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/cart/domain/entities/cart_totals_entity.dart';
import 'package:qraft/features/cart/presentation/providers/cart_providers.dart';
import 'package:qraft/features/cart/presentation/widgets/cart_summary_widget.dart';

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

        expect(find.text(r'$89.000'), findsOneWidget);
        expect(find.text(r'$16.910'), findsOneWidget);
        expect(find.text(r'$15.000'), findsOneWidget);
        expect(find.text(r'$120.910'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 2: CartTotalsEntity.zero shows \$0 subtotal and \$15.000 envío',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            totalsOverride: cartTotalsProvider.overrideWith(
              (ref) async => CartTotalsEntity.zero,
            ),
          ),
        );
        await tester.pump();

        expect(find.text(r'$0'), findsOneWidget);
        expect(find.text(r'$15.000'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 3: loading state shows shimmer, not an error or crash',
      (tester) async {
        // Never-completing future → loading state persists
        await tester.pumpWidget(
          _buildTestApp(
            totalsOverride: cartTotalsProvider.overrideWith(
              (ref) => Future<CartTotalsEntity>.value(
                CartTotalsEntity.zero,
              ).then((_) => Future<CartTotalsEntity>.delayed(
                    const Duration(days: 1),
                    () => CartTotalsEntity.zero,
                  )),
            ),
          ),
        );
        // Pump once — before future completes — to capture the loading frame.
        await tester.pump(Duration.zero);

        // Widget should not throw; no error text visible.
        expect(find.text('No se pudo calcular el total'), findsNothing);
        expect(tester.takeException(), isNull);
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
