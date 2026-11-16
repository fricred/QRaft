import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../qr_generator/presentation/controllers/qr_customization_controller.dart';
import '../../qr_generator/presentation/pages/qr_canvas_editor_screen.dart';
import '../../qr_library/presentation/providers/qr_library_providers.dart';
import '../data/dynamic_qr_repository.dart';
import 'change_content_screen.dart';
import 'checkout_screen.dart';
import 'dq_ui.dart';

class DynamicQrDetailScreen extends ConsumerStatefulWidget {
  const DynamicQrDetailScreen({super.key, required this.redirectId});
  final String redirectId;

  @override
  ConsumerState<DynamicQrDetailScreen> createState() => _DynamicQrDetailScreenState();
}

class _DynamicQrDetailScreenState extends ConsumerState<DynamicQrDetailScreen> {
  int _days = 7;
  bool _busy = false;

  void _refresh() {
    ref.invalidate(dynamicQrProvider(widget.redirectId));
    ref.invalidate(myDynamicQrsProvider);
    ref.invalidate(userQRCodesProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dynamicQrErrorText(context, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({required String title, required String body, required String yes, bool danger = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kDqSurface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: kDqMuted, height: 1.45)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(dqT(ctx, 'Cancelar', 'Cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger ? kDqError : Colors.white, foregroundColor: kDqBg),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _togglePause(DynamicQr code) async {
    final pause = code.status == DynamicQrStatus.active;
    if (pause &&
        !await _confirm(
          title: dqT(context, '¿Pausar este código?', 'Pause this code?'),
          body: dqT(context, 'Quien lo escanee verá “Este código está pausado” hasta que lo reactives. No pierdes nada.',
              'People who scan it will see “This code is paused” until you resume it. Nothing is lost.'),
          yes: dqT(context, 'Pausar', 'Pause'),
        )) {
      return;
    }
    await _run(() => ref.read(dynamicQrRepositoryProvider).setPaused(code.redirectId, pause));
  }

  Future<void> _delete(DynamicQr code) async {
    if (!await _confirm(
      title: dqT(context, '¿Eliminar este código?', 'Delete this code?'),
      body: dqT(context,
          'Los códigos impresos dejarán de funcionar para siempre y no se puede deshacer. No se reembolsa el pago. Si solo quieres detenerlo un tiempo, usa Pausar.',
          'Printed copies stop working forever and this can’t be undone. The payment isn’t refunded. To stop it for a while, use Pause.'),
      yes: dqT(context, 'Eliminar', 'Delete'),
      danger: true,
    )) {
      return;
    }
    await _run(() async {
      await ref.read(dynamicQrRepositoryProvider).revoke(code.redirectId);
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _editDesign(DynamicQr code) async {
    final qr = code.qr;
    if (qr == null || code.contentType == null) return;
    // The editor parses the content to fill its form; on save it keeps the printed link.
    final editing = qr.copyWith(data: code.payload, slug: code.slug);
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QRCanvasEditorScreen(qrType: code.contentType!, template: kQrTemplates.first, editingQR: editing),
    ));
    _refresh();
  }

  void _history(DynamicQr code) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kDqSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final h = ref.watch(dynamicQrHistoryProvider(code.redirectId));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: h.when(
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: kDqNeon))),
              error: (e, _) => Text(dynamicQrErrorText(ctx, e), style: const TextStyle(color: kDqMuted)),
              data: (items) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(dqT(ctx, 'Historial de cambios', 'Change history'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (items.isEmpty) Text(dqT(ctx, 'Todavía no has cambiado lo que muestra.', "You haven't changed what it shows yet."), style: const TextStyle(color: kDqMuted)),
                for (final it in items.take(8))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(typeIcon(it.contentType), color: kDqMuted),
                    title: Text(describeContent(ctx, it.contentType, it.payload), style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${it.changedAt.day}/${it.changedAt.month}/${it.changedAt.year}', style: const TextStyle(color: kDqMuted)),
                    trailing: TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _run(() => ref.read(dynamicQrRepositoryProvider).undo(code.redirectId, it.id));
                        ref.invalidate(dynamicQrHistoryProvider(code.redirectId));
                      },
                      child: Text(dqT(ctx, 'Volver a esto', 'Restore')),
                    ),
                  ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dynamicQrProvider(widget.redirectId));
    return Scaffold(
      backgroundColor: kDqBg,
      appBar: AppBar(
        backgroundColor: kDqBg,
        foregroundColor: Colors.white,
        title: Text(async.value?.name ?? '', overflow: TextOverflow.ellipsis),
        actions: [
          if (async.value != null) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: DynamicStatusChip(async.value!.status))),
        ],
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: kDqNeon)),
          error: (e, _) => Center(child: Text(dynamicQrErrorText(context, e), style: const TextStyle(color: kDqMuted))),
          data: (code) => code == null
              ? Center(child: Text(dqT(context, 'Este código ya no existe.', 'This code no longer exists.'), style: const TextStyle(color: kDqMuted)))
              : AbsorbPointer(absorbing: _busy, child: _body(code)),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kDqSurface, borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  Widget _body(DynamicQr code) {
    final pending = code.status == DynamicQrStatus.pendingPayment;
    final paused = code.status == DynamicQrStatus.paused;
    final editable = code.status == DynamicQrStatus.active || paused;
    final customization = code.qr?.customization ?? const QRCustomization();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(children: [
          DynamicQrImage(data: code.url, customization: customization, size: 132, dimmed: paused || pending),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dqT(context, 'Link del código', 'Code link'), style: const TextStyle(color: kDqMuted, fontSize: 13)),
              const SizedBox(height: 4),
              Text(code.shortUrl, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: kDqLine), minimumSize: const Size(0, 44)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code.url));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dqT(context, 'Link copiado', 'Link copied'))));
                  },
                  child: Text(dqT(context, 'Copiar', 'Copy')),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: kDqLine), minimumSize: const Size(0, 44)),
                  onPressed: () => launchUrl(Uri.parse(code.url), mode: LaunchMode.externalApplication),
                  child: Text(dqT(context, 'Probar link', 'Test link')),
                ),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        if (pending)
          _card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(dqT(context, 'Falta confirmar el pago', 'Payment not confirmed yet'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                dqT(context, 'Si ya pagaste con efectivo o saldo, se activa solo cuando Google Play lo confirme. Si no, completa el pago.',
                    'If you paid with cash or carrier billing, it turns on once Google Play confirms it. Otherwise, finish the payment.'),
                style: const TextStyle(color: kDqMuted, height: 1.45),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('dynamic_detail_pay_button'),
                style: FilledButton.styleFrom(backgroundColor: kDqNeon, foregroundColor: kDqOnNeon, minimumSize: const Size.fromHeight(52)),
                onPressed: () async {
                  await payPendingDynamicQr(context, code);
                  _refresh();
                },
                child: Text(dqT(context, 'Completar pago', 'Finish payment'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        if (!pending)
          _card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Icon(typeIcon(code.contentType), color: kDqNeon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(dqT(context, 'Este código ahora muestra', 'This code now shows'), style: const TextStyle(color: kDqMuted, fontSize: 13)),
                    Text(describeContent(context, code.contentType, code.payload), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('dynamic_detail_change_content_button'),
                style: FilledButton.styleFrom(backgroundColor: kDqNeon, foregroundColor: kDqOnNeon, minimumSize: const Size.fromHeight(52)),
                onPressed: editable
                    ? () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChangeContentScreen(code: code)));
                        _refresh();
                      }
                    : null,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(dqT(context, 'Cambiar lo que muestra', 'Change what it shows'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Text(dqT(context, 'El código impreso no cambia.', 'The printed code stays the same.'), style: const TextStyle(color: kDqMuted, fontSize: 13)),
            ]),
          ),
        if (!pending) ...[
          const SizedBox(height: 16),
          _ScansCard(code: code, days: _days, onDays: (d) => setState(() => _days = d)),
        ],
        if (paused) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF3A424E), borderRadius: BorderRadius.circular(14)),
            child: Text(dqT(context, 'Pausado: quien escanee verá “Este código está pausado”. Tu contenido y escaneos se conservan.',
                'Paused: people who scan it see “This code is paused”. Your content and scans are kept.'), style: const TextStyle(color: Colors.white, height: 1.45)),
          ),
        ],
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            if (editable)
              _action(paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  paused ? dqT(context, 'Reactivar', 'Resume') : dqT(context, 'Pausar', 'Pause'), () => _togglePause(code),
                  key: const Key('dynamic_detail_pause_button')),
            _action(Icons.palette_outlined, dqT(context, 'Diseño', 'Design'), () => _editDesign(code)),
            _action(Icons.ios_share_rounded, dqT(context, 'Compartir', 'Share'),
                () => SharePlus.instance.share(ShareParams(text: '${code.name}: ${code.url}'))),
            if (!pending) _action(Icons.history_rounded, dqT(context, 'Historial', 'History'), () => _history(code)),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kDqError, minimumSize: const Size.fromHeight(48)),
          onPressed: () => _delete(code),
          child: Text(dqT(context, 'Eliminar código', 'Delete code')),
        ),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap, {Key? key}) => Material(
        color: kDqSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _ScansCard extends ConsumerWidget {
  const _ScansCard({required this.code, required this.days, required this.onDays});
  final DynamicQr code;
  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scans = ref.watch(dynamicQrScansProvider((code.redirectId, days)));
    final data = scans.value ?? List.filled(days, 0);
    final total = data.fold<int>(0, (a, b) => a + b);
    final max = data.fold<int>(1, (a, b) => b > a ? b : a);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kDqSurface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(dqT(context, 'Escaneos', 'Scans'), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 7, label: Text(dqT(context, '7 días', '7 days'))),
              ButtonSegment(value: 30, label: Text(dqT(context, '30 días', '30 days'))),
            ],
            selected: {days},
            onSelectionChanged: (s) => onDays(s.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              foregroundColor: Colors.white,
              selectedForegroundColor: kDqBg,
              selectedBackgroundColor: Colors.white,
              side: const BorderSide(color: kDqLine),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('$total', dqT(context, 'en $days días', 'in $days days')),
          const SizedBox(width: 24),
          _stat('${code.scanCount}', dqT(context, 'en total', 'all time')),
        ]),
        const SizedBox(height: 12),
        Semantics(
          label: dqT(context, 'Escaneos por día, últimos $days días: $total en total', 'Scans per day, last $days days: $total total'),
          child: SizedBox(
            height: 88,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < data.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: days == 7 ? 4 : 1),
                    child: FractionallySizedBox(
                      heightFactor: data[i] == 0 ? 0.03 : data[i] / max,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: i == data.length - 1 ? kDqNeon : const Color(0xFF3F8F6E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: kDqMuted, fontSize: 13)),
      ]);
}
