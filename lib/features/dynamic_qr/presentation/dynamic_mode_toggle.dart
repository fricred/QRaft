import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dq_ui.dart';
import 'purchase_flow.dart';

/// "Generar QR" mode switch: Estático (free quota) | Dinámico (paid, featured).
/// The Dynamic tab is the wider, highlighted one: icon + price pill, neon accent
/// even when not selected (design "Opción 2B final").
class DynamicModeToggle extends ConsumerWidget {
  const DynamicModeToggle({super.key, required this.dynamic, required this.onChanged, this.staticCaption});

  final bool dynamic;
  final ValueChanged<bool> onChanged;

  /// e.g. "5/5 gratis usados"; null hides it.
  final String? staticCaption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = ref.watch(dynamicQrPackageProvider).value?.storeProduct.priceString ?? 'US\$9.99';
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: _Tab(
            key: const Key('generator_mode_static'),
            selected: !dynamic,
            onTap: () => onChanged(false),
            decoration: !dynamic
                ? BoxDecoration(
                    color: kDqSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDqLine),
                  )
                : BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.transparent)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                Icon(Icons.qr_code_2_rounded, size: 16, color: !dynamic ? Colors.white : kDqMuted),
                const SizedBox(width: 6),
                Text(dqT(context, 'Estático', 'Static'),
                    style: TextStyle(color: !dynamic ? Colors.white : kDqMuted, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              if (staticCaption != null) ...[
                const SizedBox(height: 4),
                Text(staticCaption!, style: const TextStyle(color: Color(0xFF9AA4B0), fontSize: 11)),
              ],
            ]),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: _Tab(
            key: const Key('generator_mode_dynamic'),
            selected: dynamic,
            onTap: () => onChanged(true),
            decoration: BoxDecoration(
              color: dynamic ? const Color(0xFF132A20) : const Color(0xFF1C2A23),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: dynamic ? kDqNeon : kDqNeon.withValues(alpha: 0.45), width: 1.5),
              boxShadow: dynamic ? [BoxShadow(color: kDqNeon.withValues(alpha: 0.28), blurRadius: 18)] : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dynamic ? kDqNeon : kDqNeon.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.swap_horiz_rounded, size: 18, color: dynamic ? kDqOnNeon : kDqNeon),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(dqT(context, 'Dinámico', 'Dynamic'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: kDqNeon, borderRadius: BorderRadius.circular(999)),
                  child: Text(price, style: const TextStyle(color: kDqOnNeon, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(dqT(context, 'Editable · todos los tipos', 'Editable · every type'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kDqMuted, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({super.key, required this.selected, required this.onTap, required this.decoration, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
