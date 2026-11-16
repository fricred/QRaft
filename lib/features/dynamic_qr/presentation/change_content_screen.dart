import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../qr_generator/domain/entities/qr_type.dart';
import '../../qr_generator/presentation/controllers/qr_customization_controller.dart';
import '../../qr_generator/presentation/pages/qr_canvas_editor_screen.dart';
import '../../qr_library/presentation/providers/qr_library_providers.dart';
import '../data/dynamic_qr_repository.dart';
import 'dq_ui.dart';

/// "Cambiar lo que muestra": edit the current content, write new content of any type, or
/// copy the content of one of the user's static QRs. Always confirmed as Antes → Ahora.
class ChangeContentScreen extends ConsumerStatefulWidget {
  const ChangeContentScreen({super.key, required this.code});
  final DynamicQr code;

  @override
  ConsumerState<ChangeContentScreen> createState() => _ChangeContentScreenState();
}

class _ChangeContentScreenState extends ConsumerState<ChangeContentScreen> {
  bool _saving = false;

  DynamicQr get code => widget.code;

  Future<void> _editCurrent() async {
    final type = code.contentType;
    final qr = code.qr;
    if (type == null || qr == null) return _newContent();
    final res = await Navigator.of(context).push<QrContentResult>(MaterialPageRoute(
      builder: (_) => QRCanvasEditorScreen(
        qrType: type,
        template: kQrTemplates.first,
        editingQR: qr.copyWith(type: type, data: code.payload),
        contentOnly: true,
      ),
    ));
    if (res != null) await _confirmAndSave(res);
  }

  Future<void> _newContent() async {
    final type = await showModalBottomSheet<QRType>(
      context: context,
      backgroundColor: kDqSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(dqT(ctx, '¿Qué quieres que muestre?', 'What should it show?'),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final t in QRType.values)
              ListTile(
                key: Key('dynamic_change_type_${t.identifier}'),
                leading: Icon(typeIcon(t), color: kDqNeon),
                title: Text(typeLabel(ctx, t), style: const TextStyle(color: Colors.white)),
                subtitle: t == QRType.wifi
                    ? Text(dqT(ctx, 'En dinámico no conecta solo: muestra la red y la contraseña.', "In dynamic it doesn't auto-connect: it shows network and password."),
                        style: const TextStyle(color: kDqMuted, fontSize: 12))
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              ),
          ]),
        ),
      ),
    );
    if (type == null || !mounted) return;
    final res = await Navigator.of(context).push<QrContentResult>(MaterialPageRoute(
      builder: (_) => QRCanvasEditorScreen(qrType: type, template: kQrTemplates.first, contentOnly: true),
    ));
    if (res != null) await _confirmAndSave(res);
  }

  Future<void> _fromLibrary() async {
    final all = await ref.read(userQRCodesProvider.future);
    final statics = all.where((q) => !q.isDynamic).toList();
    if (!mounted) return;
    final picked = await showModalBottomSheet<QrContentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kDqSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            Text(dqT(ctx, 'Usar uno de mis QR', 'Use one of my QRs'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(dqT(ctx, 'Copiamos su contenido. Ese QR no cambia y puedes borrarlo sin afectar este.',
                "We copy its content. That QR doesn't change and you can delete it without affecting this one."), style: const TextStyle(color: kDqMuted, height: 1.45)),
            const SizedBox(height: 12),
            if (statics.isEmpty)
              Text(dqT(ctx, 'No tienes QR estáticos guardados.', "You don't have saved static QRs."), style: const TextStyle(color: kDqMuted)),
            for (final q in statics)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(typeIcon(q.type), color: kDqNeon),
                title: Text(q.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(describeContent(ctx, q.type, q.data), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDqMuted)),
                onTap: () => Navigator.pop(ctx, QrContentResult(type: q.type, payload: q.data, display: q.displayData)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await _confirmAndSave(picked);
  }

  Future<void> _confirmAndSave(QrContentResult next) async {
    if (!mounted) return;
    final before = describeContent(context, code.contentType, code.payload);
    final after = describeContent(context, next.type, next.payload);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kDqSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(dqT(ctx, '¿Cambiar lo que muestra?', 'Change what it shows?'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _box(dqT(ctx, 'ANTES', 'BEFORE'), before, false),
            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Icon(Icons.arrow_downward_rounded, color: kDqMuted)),
            _box(dqT(ctx, 'AHORA', 'NOW'), after, true),
            if (next.type == QRType.wifi) ...[
              const SizedBox(height: 12),
              Text(dqT(ctx, 'En un QR dinámico, el WiFi no conecta solo: quien escanee verá la red y copiará la contraseña.',
                  "In a dynamic QR, WiFi doesn't auto-connect: people see the network and copy the password."), style: const TextStyle(color: kDqAmber, height: 1.45)),
            ],
            const SizedBox(height: 12),
            Text(dqT(ctx, 'Todos los códigos impresos mostrarán esto desde ya. Puedes deshacerlo desde el historial.',
                'Every printed copy shows this right away. You can undo it from the history.'), style: const TextStyle(color: kDqMuted, height: 1.45)),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('dynamic_change_confirm_button'),
              style: FilledButton.styleFrom(backgroundColor: kDqNeon, foregroundColor: kDqOnNeon, minimumSize: const Size.fromHeight(56)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dqT(ctx, 'Sí, cambiar', 'Yes, change it'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: kDqMuted, minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dqT(ctx, 'Seguir editando', 'Keep editing')),
            ),
          ]),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(dynamicQrRepositoryProvider).setContent(code.redirectId, type: next.type, payload: next.payload, display: next.display);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dqT(context, 'Listo: el código ya muestra lo nuevo', 'Done: the code now shows the new content'))));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dynamicQrErrorText(context, e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _box(String label, String text, bool highlight) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? kDqNeon.withValues(alpha: 0.08) : kDqBg,
          border: Border.all(color: highlight ? kDqNeon : kDqLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: highlight ? const Color(0xFF5CF0B4) : kDqMuted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ]),
      );

  Widget _path(IconData icon, String title, String body, VoidCallback onTap, {Key? key}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: kDqSurface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(20),
            onTap: _saving ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Icon(icon, color: kDqNeon, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(body, style: const TextStyle(color: kDqMuted, fontSize: 14, height: 1.4)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: kDqMuted),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDqBg,
      appBar: AppBar(
        backgroundColor: kDqBg,
        foregroundColor: Colors.white,
        title: Text(dqT(context, 'Cambiar lo que muestra', 'Change what it shows')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('${dqT(context, 'Ahora muestra', 'Now shows')}: ${describeContent(context, code.contentType, code.payload)}',
                style: const TextStyle(color: kDqMuted, fontSize: 14)),
            const SizedBox(height: 16),
            if (_saving) const LinearProgressIndicator(color: kDqNeon),
            _path(Icons.edit_rounded, dqT(context, 'Editar el actual', 'Edit the current one'),
                dqT(context, 'Corrige o actualiza lo que ya muestra.', 'Fix or update what it shows.'), _editCurrent,
                key: const Key('dynamic_change_edit_current')),
            _path(Icons.add_rounded, dqT(context, 'Contenido nuevo', 'New content'),
                dqT(context, 'Link, texto, evento, contacto, ubicación, WiFi o email.', 'Link, text, event, contact, location, WiFi or email.'), _newContent,
                key: const Key('dynamic_change_new_content')),
            _path(Icons.grid_view_rounded, dqT(context, 'Usar uno de mis QR', 'Use one of my QRs'),
                dqT(context, 'Copia el contenido de un QR de tu biblioteca.', 'Copy the content of a QR from your library.'), _fromLibrary,
                key: const Key('dynamic_change_from_library')),
          ],
        ),
      ),
    );
  }
}
