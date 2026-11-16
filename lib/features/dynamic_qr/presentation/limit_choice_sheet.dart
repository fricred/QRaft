import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dq_ui.dart';
import 'purchase_flow.dart';

enum LimitChoice { pro, dynamic }

/// Free plan full: go Pro, or create a paid dynamic QR (it doesn't count toward the limit).
Future<LimitChoice?> showLimitChoiceSheet(BuildContext context, {int? freeLimit}) {
  return showModalBottomSheet<LimitChoice>(
    context: context,
    backgroundColor: kDqSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => Consumer(builder: (ctx, ref, _) {
      final price = ref.watch(dynamicQrPackageProvider).value?.storeProduct.priceString ?? 'US\$9.99';
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(dqT(ctx, 'Llegaste a tus ${freeLimit ?? 5} QR gratis', "You've used your ${freeLimit ?? 5} free QRs"),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              dqT(ctx, 'Hazte Pro para crear todos los que quieras, o crea un QR dinámico: no cuenta en el límite.',
                  'Go Pro to create as many as you want, or create a dynamic QR: it doesn\'t count toward the limit.'),
              style: const TextStyle(color: kDqMuted, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('limit_choice_pro_button'),
              style: FilledButton.styleFrom(backgroundColor: kDqNeon, foregroundColor: kDqOnNeon, minimumSize: const Size.fromHeight(56)),
              onPressed: () => Navigator.pop(ctx, LimitChoice.pro),
              child: Text(dqT(ctx, 'Ver planes Pro', 'See Pro plans'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('limit_choice_dynamic_button'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: kDqLine), minimumSize: const Size.fromHeight(56)),
              onPressed: () => Navigator.pop(ctx, LimitChoice.dynamic),
              child: Text(dqT(ctx, 'Crear un QR dinámico · $price', 'Create a dynamic QR · $price'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: kDqMuted, minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(ctx),
              child: Text(dqT(ctx, 'Ahora no', 'Not now')),
            ),
          ]),
        ),
      );
    }),
  );
}
