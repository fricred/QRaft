import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../qr_generator/domain/entities/qr_type.dart';
import 'dq_ui.dart';
import 'purchase_flow.dart';

enum SaveKind { static, dynamic }

/// "¿Qué tipo de código quieres?" — Static (free, default) or Dynamic (paid, one-time).
/// With the free quota used up ([freeQuotaLeft] false) Static is no longer offered as free:
/// it says "Requiere Pro" and Dynamic is preselected.
Future<SaveKind?> showSaveKindSheet(BuildContext context, {required QRType qrType, bool freeQuotaLeft = true, int? freeLimit, bool preselectDynamic = false}) {
  return showModalBottomSheet<SaveKind>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kDqSurface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _SaveKindSheet(qrType: qrType, freeQuotaLeft: freeQuotaLeft, freeLimit: freeLimit, preselectDynamic: preselectDynamic),
  );
}

class _SaveKindSheet extends ConsumerStatefulWidget {
  const _SaveKindSheet({required this.qrType, required this.freeQuotaLeft, this.freeLimit, this.preselectDynamic = false});
  final QRType qrType;
  final bool freeQuotaLeft;
  final int? freeLimit;
  final bool preselectDynamic;

  @override
  ConsumerState<_SaveKindSheet> createState() => _SaveKindSheetState();
}

class _SaveKindSheetState extends ConsumerState<_SaveKindSheet> {
  late SaveKind _kind = widget.freeQuotaLeft && !widget.preselectDynamic ? SaveKind.static : SaveKind.dynamic;

  @override
  Widget build(BuildContext context) {
    final price = ref.watch(dynamicQrPackageProvider).value?.storeProduct.priceString ?? 'US\$9.99';
    final dyn = _kind == SaveKind.dynamic;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Semantics(
          explicitChildNodes: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF3A424E), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(dqT(context, '¿Qué tipo de código quieres?', 'Which kind of code?'),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _Option(
                key: const Key('save_kind_static_option'),
                selected: !dyn,
                title: dqT(context, 'Estático', 'Static'),
                trailing: widget.freeQuotaLeft ? dqT(context, 'Gratis', 'Free') : dqT(context, 'Requiere Pro', 'Requires Pro'),
                body: widget.freeQuotaLeft
                    ? dqT(context, 'El contenido queda fijo dentro del código. Ideal si nunca va a cambiar.',
                        'The content is fixed inside the code. Best if it will never change.')
                    : dqT(context, 'Ya usaste tus ${widget.freeLimit ?? 5} QR estáticos gratis. Con Pro guardas todos los que quieras.',
                        "You've used your ${widget.freeLimit ?? 5} free static QRs. With Pro you can save as many as you want."),
                onTap: () => setState(() => _kind = SaveKind.static),
              ),
              const SizedBox(height: 12),
              _Option(
                key: const Key('save_kind_dynamic_option'),
                selected: dyn,
                title: dqT(context, 'Dinámico', 'Dynamic'),
                trailing: price,
                trailingSub: dqT(context, 'pago único · sin mensualidad', 'one-time · no subscription'),
                body: dqT(context, 'Imprímelo una vez y cambia lo que muestra cuando quieras.',
                    'Print it once and change what it shows whenever you want.'),
                bullets: [
                  dqT(context, 'Edita el contenido sin reimprimir', 'Edit the content without reprinting'),
                  dqT(context, 'Cambia de tipo: link, evento, contacto, texto…', 'Switch type: link, event, contact, text…'),
                  dqT(context, 'Mira cuántas veces lo escanean', 'See how many times it is scanned'),
                  dqT(context, 'Pausa el código cuando lo necesites', 'Pause the code whenever you need'),
                ],
                onTap: () => setState(() => _kind = SaveKind.dynamic),
              ),
              if (dyn && widget.qrType == QRType.wifi) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kDqAmber.withValues(alpha: 0.10),
                    border: Border.all(color: kDqAmber.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    dqT(context,
                        'WiFi dinámico no conecta solo: quien escanee verá la red y podrá copiar la contraseña. Para conexión en un toque, usa Estático.',
                        "Dynamic WiFi doesn't auto-connect: people see the network and copy the password. For one-tap joining, use Static."),
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const Key('save_kind_continue_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: kDqNeon,
                    foregroundColor: kDqOnNeon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => Navigator.of(context).pop(_kind),
                  child: Text(dyn
                      ? dqT(context, 'Continuar · $price', 'Continue · $price')
                      : widget.freeQuotaLeft
                          ? dqT(context, 'Guardar QR', 'Save QR')
                          : dqT(context, 'Ver planes Pro', 'See Pro plans')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.selected,
    required this.title,
    required this.trailing,
    required this.body,
    required this.onTap,
    this.trailingSub,
    this.bullets = const [],
  });

  final bool selected;
  final String title;
  final String trailing;
  final String? trailingSub;
  final String body;
  final List<String> bullets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? kDqNeon.withValues(alpha: 0.07) : kDqBg,
            border: Border.all(color: selected ? kDqNeon : kDqLine, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? kDqNeon : kDqLine),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(trailing, style: TextStyle(color: (trailingSub?.isNotEmpty ?? false) ? kDqNeon : Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  if (trailingSub != null && trailingSub!.isNotEmpty) Text(trailingSub!, style: const TextStyle(color: kDqMuted, fontSize: 12)),
                ]),
              ]),
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 8),
                child: Text(body, style: const TextStyle(color: kDqMuted, fontSize: 14, height: 1.45)),
              ),
              for (final b in bullets)
                Padding(
                  padding: const EdgeInsets.only(left: 36, top: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.check_rounded, size: 18, color: kDqNeon),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b, style: const TextStyle(color: Colors.white, fontSize: 14))),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
