import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para manejar el idioma actual de la aplicación
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'app_locale';
  
  LocaleNotifier() : super(const Locale('en', '')) {
    _loadLocale();
  }
  
  /// Carga el idioma guardado desde SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      
      if (localeCode != null) {
        switch (localeCode) {
          case 'en':
            state = const Locale('en', '');
            break;
          case 'es':
            state = const Locale('es', '');
            break;
          default:
            // Usar idioma del sistema si está soportado, sino inglés
            final systemLocale = PlatformDispatcher.instance.locale;
            if (['en', 'es'].contains(systemLocale.languageCode)) {
              state = Locale(systemLocale.languageCode, '');
            } else {
              state = const Locale('en', '');
            }
        }
      } else {
        // Primera vez - usar idioma del sistema si está soportado
        final systemLocale = PlatformDispatcher.instance.locale;
        if (['en', 'es'].contains(systemLocale.languageCode)) {
          state = Locale(systemLocale.languageCode, '');
          await _saveLocale(systemLocale.languageCode);
        }
      }
    } catch (e) {
      // En caso de error, usar inglés por defecto
      state = const Locale('en', '');
    }
  }
  
  /// Cambia el idioma y lo guarda en SharedPreferences
  Future<void> changeLocale(String languageCode) async {
    if (['en', 'es'].contains(languageCode)) {
      state = Locale(languageCode, '');
      await _saveLocale(languageCode);
    }
  }
  
  /// Guarda el idioma en SharedPreferences
  Future<void> _saveLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
    } catch (e) {
      // Error al guardar - no es crítico
      debugPrint('Error saving locale: $e');
    }
  }
  
  /// Obtiene el nombre del idioma actual en el idioma actual
  String getCurrentLanguageName() {
    switch (state.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'English';
    }
  }
  
  /// Lista de idiomas soportados para la UI
  List<LanguageOption> getSupportedLanguages() {
    return [
      LanguageOption(
        code: 'en',
        name: 'English',
        nativeName: 'English',
      ),
      LanguageOption(
        code: 'es', 
        name: 'Spanish',
        nativeName: 'Español',
      ),
    ];
  }
}

/// Clase para representar una opción de idioma
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  
  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

/// Provider global para el manejo de idioma
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});