import 'package:supabase_flutter/supabase_flutter.dart';

import '../../qr_generator/data/models/qr_code_model.dart';
import '../../qr_generator/domain/entities/qr_code_entity.dart';
import '../../qr_generator/domain/entities/qr_type.dart';

/// Server state of a dynamic QR (mirrors `redirects.status`).
enum DynamicQrStatus {
  pendingPayment('pending_payment'),
  active('active'),
  paused('paused'),
  revoked('revoked'),
  blocked('blocked');

  const DynamicQrStatus(this.wire);
  final String wire;

  static DynamicQrStatus fromWire(String? v) =>
      values.firstWhere((s) => s.wire == v, orElse: () => DynamicQrStatus.pendingPayment);
}

/// A paid dynamic QR: the printed `scanqraft.app/<slug>` and what it shows now.
class DynamicQr {
  const DynamicQr({
    required this.redirectId,
    required this.slug,
    required this.status,
    required this.contentType,
    required this.payload,
    required this.scanCount,
    required this.createdAt,
    this.lastScannedAt,
    this.contentUpdatedAt,
    this.qr,
  });

  final String redirectId;
  final String slug;
  final DynamicQrStatus status;
  final QRType? contentType;
  final String payload;
  final int scanCount;
  final DateTime createdAt;
  final DateTime? lastScannedAt;
  final DateTime? contentUpdatedAt;

  /// The library QR (name + design) printed for this code.
  final QRCodeEntity? qr;

  String get url => 'https://scanqraft.app/$slug';
  String get shortUrl => 'scanqraft.app/$slug';
  String get name => qr?.name ?? shortUrl;

  factory DynamicQr.fromJson(Map<String, dynamic> j) {
    final qrJson = j['qr_codes'];
    QRCodeEntity? qr;
    if (qrJson is Map<String, dynamic>) {
      try {
        qr = QRCodeModel.fromJson(qrJson);
      } catch (_) {
        qr = null;
      }
    }
    DateTime? ts(String k) => j[k] == null ? null : DateTime.parse(j[k] as String).toLocal();
    final type = j['content_type'] as String?;
    return DynamicQr(
      redirectId: j['id'] as String,
      slug: j['slug'] as String,
      status: DynamicQrStatus.fromWire(j['status'] as String?),
      contentType: type == null
          ? null
          : QRType.values.where((t) => t.identifier == type).firstOrNull,
      payload: ((j['content'] as Map?)?['payload'] as String?) ?? '',
      scanCount: (j['scan_count'] as num?)?.toInt() ?? 0,
      createdAt: ts('created_at') ?? DateTime.now(),
      lastScannedAt: ts('last_scanned_at'),
      contentUpdatedAt: ts('content_updated_at'),
      qr: qr,
    );
  }
}

class DynamicQrHistoryEntry {
  const DynamicQrHistoryEntry({
    required this.id,
    required this.contentType,
    required this.payload,
    required this.changedAt,
  });

  final String id;
  final QRType? contentType;
  final String payload;
  final DateTime changedAt;
}

/// Server error codes returned by the `dynamic-qr` function (`{error: ...}`).
class DynamicQrException implements Exception {
  const DynamicQrException(this.code);
  final String code;

  @override
  String toString() => 'DynamicQrException($code)';
}

/// Reserve result: the new code exists in `pending_payment` until a purchase is applied.
class DynamicQrReservation {
  const DynamicQrReservation({required this.redirectId, required this.qrCodeId, required this.slug});
  final String redirectId;
  final String qrCodeId;
  final String slug;
}

class DynamicQrRepository {
  DynamicQrRepository(this._client);
  final SupabaseClient _client;

  static const _select =
      'id, slug, status, content_type, content, scan_count, last_scanned_at, content_updated_at, created_at, '
      'qr_codes(*)';

  /// Every code the user owns except deleted ones, newest first. RLS limits rows to the owner.
  Future<List<DynamicQr>> listMine() async {
    final rows = await _client
        .from('redirects')
        .select(_select)
        .neq('status', 'revoked')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => DynamicQr.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<DynamicQr?> get(String redirectId) async {
    final row = await _client.from('redirects').select(_select).eq('id', redirectId).maybeSingle();
    return row == null ? null : DynamicQr.fromJson(row);
  }

  /// Scans per day for the last [days] days (missing days = 0), oldest first.
  Future<List<int>> dailyScans(String redirectId, {required int days}) async {
    final today = DateTime.now().toUtc();
    final from = DateTime.utc(today.year, today.month, today.day).subtract(Duration(days: days - 1));
    final rows = await _client
        .from('redirect_scan_daily')
        .select('day, scans')
        .eq('redirect_id', redirectId)
        .gte('day', from.toIso8601String().substring(0, 10));
    final byDay = {
      for (final r in rows as List) (r['day'] as String): (r['scans'] as num).toInt(),
    };
    return List.generate(days, (i) {
      final d = from.add(Duration(days: i)).toIso8601String().substring(0, 10);
      return byDay[d] ?? 0;
    });
  }

  Future<List<DynamicQrHistoryEntry>> history(String redirectId) async {
    final rows = await _client
        .from('redirect_history')
        .select('id, content_type, content, changed_at')
        .eq('redirect_id', redirectId)
        .order('changed_at', ascending: false)
        .limit(20);
    return (rows as List).map((r) {
      final type = r['content_type'] as String?;
      return DynamicQrHistoryEntry(
        id: r['id'] as String,
        contentType: QRType.values.where((t) => t.identifier == type).firstOrNull,
        payload: ((r['content'] as Map?)?['payload'] as String?) ?? '',
        changedAt: DateTime.parse(r['changed_at'] as String).toLocal(),
      );
    }).toList();
  }

  /// Unused paid codes (bought but not linked to a code yet).
  Future<int> unusedCredits() async {
    final rows = await _client
        .from('dynamic_qr_purchases')
        .select('id')
        .eq('status', 'owned')
        .isFilter('redirect_id', null);
    return (rows as List).length;
  }

  Future<Map<String, dynamic>> _call(String action, Map<String, dynamic> body) async {
    try {
      final res = await _client.functions.invoke('dynamic-qr', body: {'action': action, ...body});
      final data = res.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map && details['error'] is String ? details['error'] as String : 'server_error';
      throw DynamicQrException(code);
    }
  }

  Future<DynamicQrReservation> reserve({
    required String name,
    required Map<String, dynamic> customization,
    required QRType type,
    required String payload,
    required String display,
  }) async {
    final r = await _call('reserve', {
      'name': name,
      'customization': customization,
      'content_type': type.identifier,
      'payload': payload,
      'display': display,
    });
    return DynamicQrReservation(
      redirectId: r['redirect_id'] as String,
      qrCodeId: r['qr_code_id'] as String,
      slug: r['slug'] as String,
    );
  }

  /// Marks [redirectId] as the code the next store purchase pays for.
  Future<void> beginCheckout(String redirectId) => _call('begin', {'redirect_id': redirectId});

  /// After a store purchase: links it to [redirectId]. Returns the code's status
  /// (`active`, or still `pending_payment` while the store hasn't confirmed the money).
  Future<DynamicQrStatus> claim(String redirectId, {String? transactionId}) async {
    final r = await _call('claim', {'redirect_id': redirectId, if (transactionId != null) 'transaction_id': transactionId});
    return DynamicQrStatus.fromWire(r['status'] as String?);
  }

  /// "Restaurar compras": applies every purchase the store knows about.
  Future<void> reconcile() => _call('reconcile', const {});

  Future<bool> useCredit(String redirectId) async {
    final r = await _call('use_credit', {'redirect_id': redirectId});
    return r['state'] == 'active';
  }

  Future<void> setContent(String redirectId, {required QRType type, required String payload, required String display}) =>
      _call('content', {
        'redirect_id': redirectId,
        'content_type': type.identifier,
        'payload': payload,
        'display': display,
      });

  Future<void> undo(String redirectId, String historyId) =>
      _call('undo', {'redirect_id': redirectId, 'history_id': historyId});

  Future<DynamicQrStatus> setPaused(String redirectId, bool paused) async {
    final r = await _call('pause', {'redirect_id': redirectId, 'paused': paused});
    return DynamicQrStatus.fromWire(r['status'] as String?);
  }

  Future<void> revoke(String redirectId) => _call('revoke', {'redirect_id': redirectId});
}
