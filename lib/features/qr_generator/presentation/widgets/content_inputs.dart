// Rich inputs for the QR content sheet (static and dynamic share it):
// place search with suggestions (Photon / OpenStreetMap, no API key), a full-screen map
// picker with "use my location", and date / time pickers for events.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/friendly_error.dart' show deviceIsSpanish;

const _kBg = Color(0xFF1A1A1A);
const _kField = Color(0xFF222222);
const _kLine = Color(0xFF3A3A3A);
const _kNeon = Color(0xFF00FF88);
const _kMuted = Color(0xFF9AA4B0);

String _t(String es, String en) => deviceIsSpanish() ? es : en;

// ─────────────────────────────────────────────────────────────────────────────
// Photon geocoder (komoot, OpenStreetMap data). Fair use: debounced typeahead only.
// ─────────────────────────────────────────────────────────────────────────────

class Place {
  const Place({
    required this.name,
    required this.detail,
    required this.lat,
    required this.lng,
  });
  final String name;
  final String detail;
  final double lat;
  final double lng;

  /// "Name, street, city" for a text field.
  String get label => detail.isEmpty ? name : '$name, $detail';
}

class PhotonGeocoder {
  PhotonGeocoder({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _headers = {'User-Agent': 'QRaft/1.3 (io.gothcorp.qraft)'};

  /// Up to 6 places for [query], biased towards [near] when given.
  Future<List<Place>> search(String query, {LatLng? near}) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final params = {
      'q': q,
      'limit': '6',
      if (near != null) 'lat': '${near.latitude}',
      if (near != null) 'lon': '${near.longitude}',
    };
    final res = await _client
        .get(Uri.https('photon.komoot.io', '/api/', params), headers: _headers)
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return const [];
    return parsePhoton(res.body);
  }

  /// Best name for a point (for "Place name" after picking on the map).
  Future<Place?> reverse(LatLng p) async {
    final res = await _client
        .get(
          Uri.https('photon.komoot.io', '/reverse', {
            'lat': '${p.latitude}',
            'lon': '${p.longitude}',
            'limit': '1',
          }),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return null;
    final list = parsePhoton(res.body);
    return list.isEmpty ? null : list.first;
  }

  /// GeoJSON FeatureCollection → places (pure, unit-tested).
  static List<Place> parsePhoton(String body) {
    try {
      final features =
          (jsonDecode(body) as Map<String, dynamic>)['features']
              as List<dynamic>? ??
          const [];
      final out = <Place>[];
      for (final f in features) {
        final props =
            (f as Map<String, dynamic>)['properties']
                as Map<String, dynamic>? ??
            const {};
        final coords =
            ((f['geometry'] as Map<String, dynamic>?)?['coordinates']
                as List<dynamic>?) ??
            const [];
        if (coords.length < 2) continue;
        final street = [
          props['street'],
          props['housenumber'],
        ].whereType<String>().join(' ');
        final name =
            (props['name'] as String?) ??
            (street.isNotEmpty ? street : (props['city'] as String? ?? ''));
        if (name.isEmpty) continue;
        final detail = <String>{
          if (street.isNotEmpty && street != name) street,
          if (props['district'] is String) props['district'] as String,
          if (props['city'] is String && props['city'] != name)
            props['city'] as String,
          if (props['country'] is String) props['country'] as String,
        }.join(', ');
        out.add(
          Place(
            name: name,
            detail: detail,
            lat: (coords[1] as num).toDouble(),
            lng: (coords[0] as num).toDouble(),
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}

final _geocoder = PhotonGeocoder();

/// Device position, asking for permission. Null when off / denied (caller explains).
Future<LatLng?> currentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
    return null;
  }
  final p = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  ).timeout(const Duration(seconds: 12));
  return LatLng(p.latitude, p.longitude);
}

const _kDefaultBias = LatLng(4.6533, -74.0836); // Bogotá: most QRaft users are in Colombia

/// Where to bias place suggestions: the last known position when location is already
/// allowed (never prompts), else Bogotá.
Future<LatLng> suggestionBias() async {
  try {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
      final p = await Geolocator.getLastKnownPosition();
      if (p != null) return LatLng(p.latitude, p.longitude);
    }
  } catch (_) {}
  return _kDefaultBias;
}

InputDecoration contentFieldDecoration(
  String label, {
  String? hint,
  Widget? suffix,
  String? error,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  errorText: error,
  suffixIcon: suffix,
  labelStyle: const TextStyle(color: Color(0xFF888888)),
  hintStyle: const TextStyle(color: Color(0xFF555555)),
  filled: true,
  fillColor: _kField,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kLine),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kLine),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _kNeon),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Place field with suggestions (event location)
// ─────────────────────────────────────────────────────────────────────────────

class PlaceAutocompleteField extends StatefulWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final VoidCallback? onChanged;

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  Timer? _debounce;
  List<Place> _results = const [];
  bool _loading = false;
  int _seq = 0;
  Future<LatLng>? _bias;

  void _onText(String v) {
    widget.onChanged?.call();
    _debounce?.cancel();
    if (v.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final my = ++_seq;
      setState(() => _loading = true);
      List<Place> r;
      try {
        r = await _geocoder.search(v, near: await (_bias ??= suggestionBias()));
      } catch (_) {
        r = const [];
      }
      if (!mounted || my != _seq) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    });
  }

  Future<void> _pickOnMap() async {
    FocusScope.of(context).unfocus();
    final picked = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (picked == null || !mounted) return;
    widget.controller.text = picked.label;
    setState(() => _results = const []);
    widget.onChanged?.call();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: 'qr_data_location_field',
          textField: true,
          child: TextField(
            controller: widget.controller,
            onChanged: _onText,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: contentFieldDecoration(
              widget.label,
              hint: widget.hint,
              suffix:
                  _loading
                      ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kNeon,
                          ),
                        ),
                      )
                      : IconButton(
                        tooltip: _t('Elegir en el mapa', 'Pick on the map'),
                        icon: const Icon(Icons.map_outlined, color: _kMuted),
                        onPressed: _pickOnMap,
                      ),
            ),
          ),
        ),
        if (_results.isNotEmpty)
          _Suggestions(
            results: _results,
            onPick: (p) {
              widget.controller.text = p.label;
              setState(() => _results = const []);
              FocusScope.of(context).unfocus();
              widget.onChanged?.call();
            },
          ),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.results, required this.onPick});
  final List<Place> results;
  final ValueChanged<Place> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kLine),
      ),
      child: Column(
        children: [
          for (final p in results)
            InkWell(
              onTap: () => onPick(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, color: _kMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (p.detail.isNotEmpty)
                            Text(
                              p.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 2, 14, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(color: Color(0xFF666666), fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location field: summary + "Elegir en el mapa" / "Usar mi ubicación"
// ─────────────────────────────────────────────────────────────────────────────

/// Writes the chosen point into [lat]/[lng] (and fills [name] when empty).
class LocationPickField extends StatelessWidget {
  const LocationPickField({
    super.key,
    required this.lat,
    required this.lng,
    required this.name,
    required this.onChanged,
  });
  final TextEditingController lat;
  final TextEditingController lng;
  final TextEditingController name;
  final VoidCallback onChanged;

  LatLng? get _point {
    final a = double.tryParse(lat.text.replaceAll(',', '.'));
    final b = double.tryParse(lng.text.replaceAll(',', '.'));
    if (a == null || b == null || a.abs() > 90 || b.abs() > 180) return null;
    return LatLng(a, b);
  }

  Future<void> _open(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _point)),
    );
    if (picked == null) return;
    lat.text = picked.lat.toStringAsFixed(6);
    lng.text = picked.lng.toStringAsFixed(6);
    if (name.text.trim().isEmpty || name.text.trim() == picked.detail) {
      name.text = picked.name;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = _point;
    return Semantics(
      identifier: 'qr_data_map_button',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Container(
          height: p == null ? 96 : 150,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _kField,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p == null ? _kNeon : _kLine),
          ),
          child:
              p == null
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_rounded, color: _kNeon),
                      const SizedBox(width: 10),
                      Text(
                        _t('Elegir en el mapa', 'Pick on the map'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                  : Stack(
                    children: [
                      IgnorePointer(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: p,
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'io.gothcorp.qraft',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: p,
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.topCenter,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFFE11D48),
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _t('Cambiar', 'Change'),
                                style: const TextStyle(
                                  color: _kNeon,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

/// Full-screen map: the pin stays in the centre and the map moves under it.
/// Search with suggestions, "Mi ubicación", Confirm → [Place] (name from reverse geocoding).
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});
  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _bogota = LatLng(4.6533, -74.0836);
  final _map = MapController();
  final _search = TextEditingController();
  late LatLng _center = widget.initial ?? _bogota;
  Timer? _debounce;
  List<Place> _results = const [];
  bool _locating = false;
  bool _confirming = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation(silent: true));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    setState(() => _locating = true);
    LatLng? p;
    try {
      p = await currentPosition();
    } catch (_) {
      p = null;
    }
    if (!mounted) return;
    setState(() => _locating = false);
    if (p == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'No pudimos obtener tu ubicación. Activa la ubicación y dale permiso a QRaft.',
                "We couldn't get your location. Turn location on and allow QRaft to use it.",
              ),
            ),
          ),
        );
      }
      return;
    }
    _center = p;
    _map.move(p, 17);
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    if (v.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final my = ++_seq;
      List<Place> r;
      try {
        r = await _geocoder.search(v, near: _center);
      } catch (_) {
        r = const [];
      }
      if (!mounted || my != _seq) return;
      setState(() => _results = r);
    });
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    Place? named;
    try {
      named = await _geocoder.reverse(_center);
    } catch (_) {
      named = null;
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      Place(
        name: named?.name ?? '',
        detail: named?.detail ?? '',
        lat: _center.latitude,
        lng: _center.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        title: Text(_t('Elegir ubicación', 'Choose location')),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial == null ? 12 : 16,
              onPositionChanged: (camera, _) => _center = camera.center,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'io.gothcorp.qraft',
                maxZoom: 19,
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          // Fixed centre pin (the tip marks the point).
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(
                  Icons.location_on,
                  color: Color(0xFFE11D48),
                  size: 48,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: contentFieldDecoration(
                      _t(
                        'Buscar dirección o lugar',
                        'Search an address or place',
                      ),
                      suffix: const Icon(Icons.search, color: _kMuted),
                    ),
                  ),
                ),
                if (_results.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: _Suggestions(
                      results: _results,
                      onPick: (p) {
                        FocusScope.of(context).unfocus();
                        setState(() => _results = const []);
                        _center = LatLng(p.lat, p.lng);
                        _map.move(_center, 17);
                      },
                    ),
                  ),
              ],
            ),
          ),
          // While choosing a suggestion the list owns the screen (no button over it).
          if (_results.isEmpty)
            Positioned(
              right: 16,
              bottom: 104,
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                tooltip: _t('Usar mi ubicación', 'Use my location'),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                onPressed: _locating ? null : () => _useMyLocation(),
                child:
                    _locating
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.my_location),
              ),
            ),
          if (_results.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: const Key('location_picker_confirm'),
                    onPressed: _confirming ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kNeon,
                      foregroundColor: const Color(0xFF04140D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      _confirming
                          ? _t('Buscando el nombre…', 'Finding the name…')
                          : _t('Usar este punto', 'Use this spot'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event date / time
// ─────────────────────────────────────────────────────────────────────────────

/// "YYYY-MM-DD HH:MM" ↔ DateTime (the editor's existing eventDate format).
String formatEventDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

DateTime? parseEventDate(String s) {
  final m = RegExp(
    r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2}):(\d{2}))?$',
  ).firstMatch(s.trim());
  if (m == null) return null;
  return DateTime(
    int.parse(m[1]!),
    int.parse(m[2]!),
    int.parse(m[3]!),
    int.parse(m[4] ?? '0'),
    int.parse(m[5] ?? '0'),
  );
}

/// Start date + start time + optional end time, written to [start] ("YYYY-MM-DD HH:MM")
/// and [end] ("HH:MM", same day; earlier than start = next day).
class EventWhenField extends StatelessWidget {
  const EventWhenField({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
    this.fallbackStart,
    this.fallbackEnd,
  });
  final TextEditingController start;
  final TextEditingController end;
  final VoidCallback onChanged;

  /// Shown when [start] is empty (an existing event's date).
  final DateTime? fallbackStart;

  /// An existing event's end, shown until a new end time is picked.
  final DateTime? fallbackEnd;

  DateTime? get _start => parseEventDate(start.text) ?? fallbackStart;

  TimeOfDay? get _end {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(end.text.trim());
    if (m == null) {
      return fallbackEnd == null ? null : TimeOfDay.fromDateTime(fallbackEnd!);
    }
    return TimeOfDay(hour: int.parse(m[1]!), minute: int.parse(m[2]!));
  }

  Future<void> _pickDate(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final cur = _start ?? DateTime(now.year, now.month, now.day, 19);
    final d = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: _t('Fecha del evento', 'Event date'),
    );
    if (d == null) return;
    start.text = formatEventDate(
      DateTime(d.year, d.month, d.day, cur.hour, cur.minute),
    );
    onChanged();
  }

  Future<void> _pickStartTime(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final cur = _start ?? DateTime(now.year, now.month, now.day, 19);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(cur),
      helpText: _t('Hora de inicio', 'Start time'),
    );
    if (t == null) return;
    start.text = formatEventDate(
      DateTime(cur.year, cur.month, cur.day, t.hour, t.minute),
    );
    onChanged();
  }

  Future<void> _pickEndTime(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final s = _start;
    final initial =
        _end ??
        (s != null
            ? TimeOfDay.fromDateTime(s.add(const Duration(hours: 2)))
            : const TimeOfDay(hour: 21, minute: 0));
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: _t('Hora de fin', 'End time'),
    );
    if (t == null) return;
    end.text =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = _start;
    final e = _end;
    final loc = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PickerTile(
          id: 'qr_data_event_date',
          icon: Icons.calendar_today_rounded,
          label: _t('Fecha', 'Date'),
          value: s == null ? null : loc.formatFullDate(s),
          placeholder: _t('Elige la fecha', 'Choose the date'),
          onTap: () => _pickDate(context),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PickerTile(
                id: 'qr_data_event_start',
                icon: Icons.schedule_rounded,
                label: _t('Empieza', 'Starts'),
                value:
                    s == null
                        ? null
                        : loc.formatTimeOfDay(TimeOfDay.fromDateTime(s)),
                placeholder: '--:--',
                onTap: () => _pickStartTime(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerTile(
                id: 'qr_data_event_end',
                icon: Icons.schedule_outlined,
                label: _t('Termina (opcional)', 'Ends (optional)'),
                value: e == null ? null : loc.formatTimeOfDay(e),
                placeholder: '--:--',
                onTap: () => _pickEndTime(context),
                onClear:
                    end.text.trim().isEmpty
                        ? null
                        : () {
                          end.clear();
                          onChanged();
                        },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.onClear,
  });
  final String id;
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: id,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          decoration: BoxDecoration(
            color: _kField,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value == null ? _kLine : _kNeon.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: value == null ? _kMuted : _kNeon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value ?? placeholder,
                      style: TextStyle(
                        color:
                            value == null
                                ? const Color(0xFF666666)
                                : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: _t('Quitar', 'Clear'),
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _kMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
