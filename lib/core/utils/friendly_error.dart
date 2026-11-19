import 'package:flutter/widgets.dart';
import 'dart:io';

/// Turns a raw exception into a short message safe to show to users.
///
/// Raw server errors (table names, constraint names, stack-like text) must never reach
/// the UI (QRAFT-1, QRAFT-4). The original error is still available to callers for logs.
String friendlyErrorMessage(Object error, {bool spanish = true}) {
  final raw = error.toString().toLowerCase();

  if (error is SocketException ||
      raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network is unreachable') ||
      raw.contains('clientexception')) {
    return spanish
        ? 'Sin conexión. Revisa tu internet e inténtalo de nuevo.'
        : 'No connection. Check your internet and try again.';
  }

  if (raw.contains('row-level security') ||
      raw.contains('42501') ||
      raw.contains('23503') ||
      raw.contains('foreign key')) {
    return spanish
        ? 'No pudimos guardar tu código. Cierra sesión, vuelve a entrar e inténtalo de nuevo.'
        : "We couldn't save your code. Sign out, sign back in and try again.";
  }

  return spanish
      ? 'Ocurrió un error inesperado. Inténtalo de nuevo.'
      : 'Something went wrong. Please try again.';
}

/// Maps an auth failure to a localized, user-safe message (QRAFT-4).
///
/// Never leaks server text, hostnames or raw exception strings. "Invalid credentials" is
/// deliberately identical for unknown email and wrong password so accounts are not revealed.
String friendlyAuthMessage(Object error, {bool spanish = true}) {
  final raw = error.toString().toLowerCase();

  String pick(String es, String en) => spanish ? es : en;

  if (error is SocketException ||
      raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('clientexception') ||
      raw.contains('network is unreachable')) {
    return pick('Sin conexión. Revisa tu internet e inténtalo de nuevo.',
        'No connection. Check your internet and try again.');
  }
  if (raw.contains('invalid login credentials') || raw.contains('invalid_credentials')) {
    return pick('Correo o contraseña incorrectos.', 'Incorrect email or password.');
  }
  if (raw.contains('email not confirmed') || raw.contains('email_not_confirmed')) {
    return pick('Debes confirmar tu correo antes de entrar. Revisa tu bandeja de entrada.',
        'Please confirm your email before signing in. Check your inbox.');
  }
  if (raw.contains('rate limit') || raw.contains('over_email_send_rate_limit') || raw.contains('too many')) {
    return pick('Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
        'Too many attempts. Wait a few minutes and try again.');
  }
  if (raw.contains('already registered') || raw.contains('user_already_exists')) {
    return pick('Ya existe una cuenta con ese correo.', 'An account with that email already exists.');
  }
  if (raw.contains('same_password') || raw.contains('different from the old password')) {
    return pick('La contraseña nueva debe ser distinta de la anterior.',
        'Your new password must be different from the old one.');
  }
  if (raw.contains('weak_password') || raw.contains('password should be')) {
    return pick('La contraseña es muy débil. Usa 8 o más caracteres, con mayúscula, minúscula y número.',
        'That password is too weak. Use 8+ characters with upper, lower case and a number.');
  }
  return pick('No pudimos completar la operación. Inténtalo de nuevo.',
      'We could not complete that. Please try again.');
}

/// The language the user picked in the app (set by the root widget); null = follow the OS.
String? appLanguageCode;

/// True when messages should be in Spanish (used where no BuildContext is available).
/// Follows the in-app language choice, falling back to the device language.
bool deviceIsSpanish() =>
    (appLanguageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode) == 'es';
