import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../domain/entities/consent_state.dart';

/// Singleton service wrapping Google's UMP SDK (shipped inside `google_mobile_ads`
/// ^5.1.0; verified via https://developers.google.com/admob/flutter/privacy on
/// 2026-05-01). Mirrors the singleton + idempotent-init pattern from
/// `lib/features/ads/data/services/admob_service.dart` lines 8-30.
///
/// The UMP API in `google_mobile_ads` is callback-based, NOT async/await. We
/// wrap each callback in a `Completer` to expose an awaitable
/// `Future<ConsentState>` API to the rest of the app.
///
/// Per D-04: `requestConsentInfoUpdate()` runs AFTER splash and BEFORE
/// `MobileAds.instance.initialize()`. Per D-05: scope is global — UMP SDK
/// auto-detects GDPR/EU jurisdictions and returns `notRequired` outside them.
/// Per D-06: deny path returns `ConsentState.denied`; callers must build
/// `AdRequest(nonPersonalizedAds: true)` (npa=1) so banners still render.
class UmpService {
  static final UmpService _instance = UmpService._internal();
  factory UmpService() => _instance;
  UmpService._internal();

  bool _isInitialized = false;
  ConsentState _state = ConsentState.unknown;

  bool get isInitialized => _isInitialized;
  ConsentState get state => _state;

  /// Idempotent. Calls google_mobile_ads' `ConsentInformation.instance.requestConsentInfoUpdate`
  /// (callback-based) and unwraps it into a `Future<ConsentState>`.
  /// Per D-05: SDK auto-detects GDPR/EU; non-GDPR returns notRequired.
  Future<ConsentState> requestConsentInfoUpdate() async {
    if (_isInitialized) return _state;

    final completer = Completer<ConsentState>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Success path — consent info now reflects the current jurisdiction.
        try {
          final status = await ConsentInformation.instance.getConsentStatus();
          _state = _mapStatus(status);
          _isInitialized = true;
          debugPrint('UMP consent info updated: $_state');
          completer.complete(_state);
        } catch (e) {
          debugPrint('UMP getConsentStatus failed after info update: $e');
          _state = ConsentState.notRequired; // fail-open
          _isInitialized = true;
          completer.complete(_state);
        }
      },
      (FormError formError) {
        debugPrint(
          'UMP requestConsentInfoUpdate failed: '
          '${formError.errorCode} ${formError.message}',
        );
        // Fail-open: treat as notRequired so app does not deadlock on consent.
        _state = ConsentState.notRequired;
        _isInitialized = true;
        completer.complete(_state);
      },
    );

    return completer.future;
  }

  /// If consent is required, present Google's hosted form. Updates state on completion.
  /// Per D-06: deny path returns ConsentState.denied; accept returns ConsentState.obtained.
  Future<ConsentState> loadAndShowConsentFormIfRequired() async {
    if (_state != ConsentState.required) return _state;

    final completer = Completer<ConsentState>();

    ConsentForm.loadAndShowConsentFormIfRequired((FormError? loadAndShowError) async {
      if (loadAndShowError != null) {
        debugPrint(
          'UMP loadAndShowConsentFormIfRequired failed: '
          '${loadAndShowError.errorCode} ${loadAndShowError.message}',
        );
        _state = ConsentState.denied; // conservative — assume deny on failure
        completer.complete(_state);
        return;
      }
      try {
        final status = await ConsentInformation.instance.getConsentStatus();
        // ConsentStatus.obtained on success — we cannot distinguish accept vs deny
        // through ConsentStatus alone. Use canRequestAds() to disambiguate:
        // - canRequestAds == true  -> personalized OR npa accepted -> ConsentState.obtained
        // - canRequestAds == false -> nothing accepted -> ConsentState.denied
        final canRequestAds = await ConsentInformation.instance.canRequestAds();
        if (status == ConsentStatus.obtained && !canRequestAds) {
          _state = ConsentState.denied;
        } else {
          _state = _mapStatus(status);
        }
        debugPrint('UMP form completed: $_state (canRequestAds=$canRequestAds)');
        completer.complete(_state);
      } catch (e) {
        debugPrint('UMP getConsentStatus after form failed: $e');
        _state = ConsentState.denied;
        completer.complete(_state);
      }
    });

    return completer.future;
  }

  /// Test hook — resets singleton state. NOT used in production code.
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _state = ConsentState.unknown;
  }

  ConsentState _mapStatus(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.required:
        return ConsentState.required;
      case ConsentStatus.notRequired:
        return ConsentState.notRequired;
      case ConsentStatus.obtained:
        return ConsentState.obtained;
      case ConsentStatus.unknown:
        return ConsentState.unknown;
    }
  }
}
