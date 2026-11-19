import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/dynamic_qr_repository.dart';
import '../../qr_generator/qr_generator_screen.dart';
import 'detail_screen.dart';
import 'dq_ui.dart';

enum _Filter { all, active, paused, pending }

/// "Mis QR dinámicos": every paid code, what it shows now, scans and state.
class DynamicQrManagerScreen extends ConsumerStatefulWidget {
  const DynamicQrManagerScreen({super.key});

  @override
  ConsumerState<DynamicQrManagerScreen> createState() => _DynamicQrManagerScreenState();
}

class _DynamicQrManagerScreenState extends ConsumerState<DynamicQrManagerScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    // Pending store payments: re-check quietly every time the manager opens.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final codes = await ref.read(myDynamicQrsProvider.future);
        if (codes.any((c) => c.status == DynamicQrStatus.pendingPayment)) {
          await _syncStore();
          await ref.read(dynamicQrRepositoryProvider).reconcile();
          if (mounted) ref.invalidate(myDynamicQrsProvider);
        }
      } catch (_) {}
    });
  }

  /// Lets RevenueCat learn about purchases the store finished outside the app (a pending
  /// payment that cleared) before the server re-reads them.
  Future<void> _syncStore() async {
    try {
      await Purchases.syncPurchases();
    } catch (_) {}
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      await _syncStore();
      await ref.read(dynamicQrRepositoryProvider).reconcile();
      ref.invalidate(myDynamicQrsProvider);
      ref.invalidate(dynamicQrCreditsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(dqT(context, 'Compras restauradas', 'Purchases restored')),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dynamicQrErrorText(context, e))));
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  /// "Generar QR" already in Dinámico mode.
  Future<void> _create() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: kDqBg,
        appBar: AppBar(backgroundColor: kDqBg, foregroundColor: Colors.white, title: Text(dqT(context, 'Nuevo QR dinámico', 'New dynamic QR'))),
        body: const QRGeneratorScreen(initialDynamic: true),
      ),
    ));
    ref.invalidate(myDynamicQrsProvider);
  }

  bool _matches(DynamicQr c) {
    final okFilter = switch (_filter) {
      _Filter.all => true,
      _Filter.active => c.status == DynamicQrStatus.active,
      _Filter.paused => c.status == DynamicQrStatus.paused,
      _Filter.pending => c.status == DynamicQrStatus.pendingPayment,
    };
    final q = _query.trim().toLowerCase();
    return okFilter && (q.isEmpty || c.name.toLowerCase().contains(q) || c.slug.contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final codes = ref.watch(myDynamicQrsProvider);
    return Scaffold(
      backgroundColor: kDqBg,
      appBar: AppBar(
        backgroundColor: kDqBg,
        foregroundColor: Colors.white,
        title: Text(dqT(context, 'Mis QR dinámicos', 'My dynamic QRs'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('dynamic_manager_new_button'),
        backgroundColor: kDqNeon,
        foregroundColor: kDqOnNeon,
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text(dqT(context, 'Nuevo QR dinámico', 'New dynamic QR'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: codes.when(
          loading: () => const Center(child: CircularProgressIndicator(color: kDqNeon)),
          error: (e, _) => _message(
            icon: Icons.cloud_off_rounded,
            title: dqT(context, 'No pudimos cargar tus códigos', "We couldn't load your codes"),
            body: dqT(context, 'Revisa tu conexión e inténtalo de nuevo.', 'Check your connection and try again.'),
            action: dqT(context, 'Reintentar', 'Retry'),
            onAction: () => ref.invalidate(myDynamicQrsProvider),
          ),
          data: (all) {
            if (all.isEmpty) {
              return _message(
                icon: Icons.qr_code_2_rounded,
                title: dqT(context, 'Aún no tienes QR dinámicos', "You don't have dynamic QRs yet"),
                body: dqT(context,
                    'Imprímelo una vez y cambia lo que muestra cuando quieras. Toca “Nuevo QR dinámico” para crear el primero.',
                    'Print it once and change what it shows whenever you want. Tap “New dynamic QR” to create your first one.'),
                action: dqT(context, '¿Cambiaste de teléfono? Restaurar compras', 'New phone? Restore purchases'),
                onAction: _restoring ? null : _restore,
              );
              // (The floating "Nuevo QR dinámico" button is the main action here too.)
            }
            final shown = all.where(_matches).toList();
            int count(_Filter f) => switch (f) {
                  _Filter.all => all.length,
                  _Filter.active => all.where((c) => c.status == DynamicQrStatus.active).length,
                  _Filter.paused => all.where((c) => c.status == DynamicQrStatus.paused).length,
                  _Filter.pending => all.where((c) => c.status == DynamicQrStatus.pendingPayment).length,
                };
            return RefreshIndicator(
              color: kDqNeon,
              onRefresh: () async => ref.invalidate(myDynamicQrsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  TextField(
                    key: const Key('dynamic_manager_search_field'),
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: dqT(context, 'Buscar por nombre o link', 'Search by name or link'),
                      hintStyle: const TextStyle(color: kDqMuted),
                      prefixIcon: const Icon(Icons.search, color: kDqMuted),
                      filled: true,
                      fillColor: kDqSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final f in _Filter.values)
                      if (f == _Filter.all || count(f) > 0)
                        ChoiceChip(
                          label: Text('${switch (f) {
                            _Filter.all => dqT(context, 'Todos', 'All'),
                            _Filter.active => dqT(context, 'Activos', 'Active'),
                            _Filter.paused => dqT(context, 'Pausados', 'Paused'),
                            _Filter.pending => dqT(context, 'Pendientes', 'Pending'),
                          }} · ${count(f)}'),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          showCheckmark: false,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          selectedColor: Colors.white,
                          backgroundColor: kDqBg,
                          side: const BorderSide(color: kDqLine),
                          labelStyle: TextStyle(color: _filter == f ? kDqBg : Colors.white, fontWeight: FontWeight.w600),
                        ),
                  ]),
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(dqT(context, 'Nada coincide con tu búsqueda.', 'Nothing matches your search.'),
                          textAlign: TextAlign.center, style: const TextStyle(color: kDqMuted)),
                    ),
                  for (final c in shown) _Tile(code: c),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('dynamic_manager_restore_button'),
                    style: TextButton.styleFrom(foregroundColor: kDqMuted, minimumSize: const Size.fromHeight(48)),
                    onPressed: _restoring ? null : _restore,
                    child: Text(dqT(context, '¿Cambiaste de teléfono? Restaurar compras', 'New phone? Restore purchases')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _message({required IconData icon, required String title, required String body, required String action, VoidCallback? onAction}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: kDqNeon.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(28)),
            child: Icon(icon, color: kDqNeon, size: 44),
          ),
        ),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(body, textAlign: TextAlign.center, style: const TextStyle(color: kDqMuted, fontSize: 15, height: 1.5)),
        const SizedBox(height: 20),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kDqNeon, minimumSize: const Size.fromHeight(48)),
          onPressed: onAction,
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.code});
  final DynamicQr code;

  String _ago(BuildContext context, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return dqT(context, 'ahora', 'now');
    if (d.inHours < 1) return dqT(context, 'hace ${d.inMinutes} min', '${d.inMinutes} min ago');
    if (d.inDays < 1) return dqT(context, 'hace ${d.inHours} h', '${d.inHours} h ago');
    return dqT(context, 'hace ${d.inDays} d', '${d.inDays} d ago');
  }

  @override
  Widget build(BuildContext context) {
    final pending = code.status == DynamicQrStatus.pendingPayment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kDqSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: Key('dynamic_manager_item_${code.slug}'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DynamicQrDetailScreen(redirectId: code.redirectId))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: kDqBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(typeIcon(code.contentType), color: kDqNeon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(code.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    DynamicStatusChip(code.status),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    pending
                        ? dqT(context, 'Se activa cuando se confirme el pago', 'Turns on once the payment is confirmed')
                        : '${dqT(context, 'Muestra', 'Shows')}: ${describeContent(context, code.contentType, code.payload)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kDqMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(code.shortUrl, style: const TextStyle(color: Color(0xFF9AA4B0), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '${code.scanCount} ${dqT(context, 'escaneos', 'scans')}'
                    '${code.lastScannedAt != null ? ' · ${dqT(context, 'último', 'last')} ${_ago(context, code.lastScannedAt!)}' : ''}',
                    style: const TextStyle(color: kDqMuted, fontSize: 13),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
