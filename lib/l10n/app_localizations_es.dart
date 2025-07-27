// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'QRaft';

  @override
  String get welcomeTitle => '¡Bienvenido a QRaft!';

  @override
  String get welcomeSubtitle => 'Tu solución completa para QR personalizados';

  @override
  String get featureCreateTitle => 'Crea QR personalizados';

  @override
  String get featureCreateDescription =>
      'Diseña y personaliza tus propios códigos QR para cualquier propósito.';

  @override
  String get featureShareTitle => 'Comparte fácilmente';

  @override
  String get featureShareDescription =>
      'Envía tus QR a tus contactos o publícalos en tus redes sociales.';

  @override
  String get featureEngraveTitle => 'Graba en materiales';

  @override
  String get featureEngraveDescription =>
      'Obtén tus QR grabados en madera, metal y otros materiales de calidad.';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta? Iniciar Sesión';

  @override
  String get mainFeatures => 'Características principales';

  @override
  String get welcomeBack => 'Bienvenido de Nuevo';

  @override
  String get signInToContinue =>
      'Inicia sesión para continuar creando códigos QR increíbles';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get enterEmail => 'Ingresa tu correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get enterPassword => 'Ingresa tu contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu Contraseña?';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get dontHaveAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get joinQRaft =>
      'Únete a QRaft y comienza a crear códigos QR increíbles';

  @override
  String get fullName => 'Nombre Completo';

  @override
  String get enterFullName => 'Ingresa tu nombre completo';

  @override
  String get createPassword => 'Crea una contraseña';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get confirmPasswordHint => 'Confirma tu contraseña';

  @override
  String get agreeToTerms =>
      'Acepto los Términos y Condiciones y la Política de Privacidad';

  @override
  String get alreadyHaveAccountSignIn => '¿Ya tienes cuenta? Iniciar Sesión';

  @override
  String get pleaseEnterEmail => 'Por favor ingresa tu correo electrónico';

  @override
  String get pleaseEnterValidEmail =>
      'Por favor ingresa un correo electrónico válido';

  @override
  String get pleaseEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get pleaseEnterName => 'Por favor ingresa tu nombre';

  @override
  String get nameMinLength => 'El nombre debe tener al menos 2 caracteres';

  @override
  String get passwordMinLengthSignUp =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordMustContainUppercase =>
      'La contraseña debe contener al menos una letra mayúscula';

  @override
  String get passwordMustContainLowercase =>
      'La contraseña debe contener al menos una letra minúscula';

  @override
  String get passwordMustContainNumber =>
      'La contraseña debe contener al menos un número';

  @override
  String get pleaseConfirmPassword => 'Por favor confirma tu contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get pleaseAgreeToTerms =>
      'Por favor acepta los Términos y Condiciones';

  @override
  String loginAttempt(String email) {
    return 'Intento de inicio de sesión: $email';
  }

  @override
  String accountCreated(String name) {
    return 'Cuenta creada para: $name';
  }

  @override
  String get forgotPasswordComingSoon =>
      'La funcionalidad de recuperar contraseña estará disponible pronto';

  @override
  String get loginSuccessful =>
      '¡Inicio de sesión exitoso! Bienvenido de vuelta.';

  @override
  String get resetPassword => 'Restablecer Contraseña';

  @override
  String get resetPasswordSubtitle => 'Ingresa tu email para recibir el enlace';

  @override
  String get enterEmailForReset => 'Ingresa tu dirección de email';

  @override
  String get sendResetLink => 'Enviar';

  @override
  String get emailSent => '¡Email Enviado!';

  @override
  String checkEmailForReset(String email) {
    return 'Hemos enviado un enlace de restablecimiento de contraseña a $email. Por favor revisa tu email y sigue las instrucciones para restablecer tu contraseña.';
  }

  @override
  String get done => 'Listo';

  @override
  String get profile => 'Perfil';

  @override
  String get anonymousUser => 'Usuario Anónimo';

  @override
  String get noEmail => 'Sin correo';

  @override
  String get changeProfilePhoto => 'Cambiar Foto de Perfil';

  @override
  String get choosePhotoSource =>
      'Elige cómo quieres actualizar tu foto de perfil';

  @override
  String get updatingProfilePhoto => 'Actualizando foto de perfil...';

  @override
  String get profilePhotoUpdatedSuccess =>
      '¡Foto de perfil actualizada con éxito!';

  @override
  String get profilePhotoUpdateFailed =>
      'Error al actualizar la foto de perfil. Inténtalo de nuevo.';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String joinedDate(String date) {
    return 'Se unió $date';
  }

  @override
  String get unknown => 'Desconocido';

  @override
  String daysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String monthsAgo(int months, String plural) {
    return 'hace $months mes$plural';
  }

  @override
  String yearsAgo(int years, String plural) {
    return 'hace $years año$plural';
  }

  @override
  String get personalInformation => 'Información Personal';

  @override
  String get displayName => 'Nombre Visible';

  @override
  String get phoneNumber => 'Número de Teléfono';

  @override
  String get bio => 'Biografía';

  @override
  String get location => 'Ubicación';

  @override
  String get website => 'Sitio Web';

  @override
  String get company => 'Empresa';

  @override
  String get jobTitle => 'Puesto de Trabajo';

  @override
  String enterField(String field) {
    return 'Ingresa $field';
  }

  @override
  String get notProvided => 'No proporcionado';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get qrCodes => 'Códigos QR';

  @override
  String get scans => 'Escaneos';

  @override
  String get orders => 'Pedidos';

  @override
  String get daysActive => 'Días Activo';

  @override
  String get quickActions => 'Acciones Rápidas';

  @override
  String get myQRCodes => 'Mis Códigos QR';

  @override
  String get scanHistory => 'Historial de Escaneos';

  @override
  String get myOrders => 'Mis Pedidos';

  @override
  String get shareProfile => 'Compartir Perfil';

  @override
  String get exportData => 'Exportar Datos';

  @override
  String get exportDataDescription => 'Descarga tus códigos QR y datos';

  @override
  String get backupSync => 'Copia de Seguridad y Sincronización';

  @override
  String get backupSyncDescription => 'Respalda tus datos en la nube';

  @override
  String get privacySecurity => 'Privacidad y Seguridad';

  @override
  String get privacySecurityDescription =>
      'Administra tu configuración de privacidad';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String featureComingSoon(String feature) {
    return '$feature estará disponible en una futura actualización.';
  }

  @override
  String get ok => 'OK';

  @override
  String get saving => 'Guardando...';

  @override
  String get save => 'Guardar';

  @override
  String failedToUpdate(String field, String error) {
    return 'Error al actualizar $field: $error';
  }

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get close => 'Cerrar';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get privacy => 'Privacidad';

  @override
  String get dataPrivacySettings => 'Configuración de datos y privacidad';

  @override
  String get helpSupport => 'Ayuda y Soporte';

  @override
  String get helpSupportDescription => 'Obtén ayuda y contacta al soporte';

  @override
  String get signOutConfirm =>
      '¿Estás seguro de que quieres cerrar sesión en tu cuenta?';

  @override
  String get signingOut => 'Cerrando sesión...';

  @override
  String get signOutFailed => 'Error al cerrar sesión. Inténtalo de nuevo.';

  @override
  String get selectPhotoSource => 'Seleccionar Fuente de Foto';

  @override
  String get choosePhotoMethod => 'Elige cómo quieres agregar tu foto';

  @override
  String get camera => 'Cámara';

  @override
  String get takeNewPhoto => 'Tomar una nueva foto';

  @override
  String get gallery => 'Galería';

  @override
  String get chooseFromPhotos => 'Elegir de las fotos';

  @override
  String failedToLoadProfile(String error) {
    return 'Error al cargar perfil: $error';
  }

  @override
  String failedToUpdateProfile(String error) {
    return 'Error al actualizar perfil: $error';
  }

  @override
  String failedToUpdateProfilePhoto(String error) {
    return 'Error al actualizar foto de perfil: $error';
  }

  @override
  String get cameraPermissionDenied =>
      'QRaft necesita acceso a tu cámara para tomar fotos para tu imagen de perfil. Permite el acceso a la cámara en la configuración de tu dispositivo.';

  @override
  String get galleryPermissionDenied =>
      'QRaft necesita acceso a tu galería de fotos para seleccionar imágenes para tu imagen de perfil. Permite el acceso al almacenamiento en la configuración de tu dispositivo.';

  @override
  String get imageSelectionCancelled => 'Selección de imagen cancelada.';

  @override
  String get retry => 'Reintentar';

  @override
  String get cropImage => 'Recortar Imagen';

  @override
  String get crop => 'Recortar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get rotateLeft => 'Rotar Izquierda';

  @override
  String get rotateRight => 'Rotar Derecha';

  @override
  String get cropInstruction =>
      'Ajusta el área de recorte arrastrando las esquinas';

  @override
  String get cropFailed => 'Error al recortar imagen. Inténtalo de nuevo.';

  @override
  String get processingImage => 'Procesando imagen...';

  @override
  String get qrScanner => 'Escáner QR';

  @override
  String get pointCameraAtQR => 'Apunta la cámara al código QR';

  @override
  String get copy => 'Copiar';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get clearAllHistory => 'Borrar todo el historial';

  @override
  String get clearAllHistoryConfirm =>
      '¿Estás seguro de que deseas borrar todo el historial?';

  @override
  String get noScansYet => 'Aún no hay escaneos';

  @override
  String get startScanningToSeeHistory =>
      'Comienza a escanear para ver el historial';

  @override
  String get startScanning => 'Comenzar a escanear';

  @override
  String get createQRCode => 'Crear Código QR';

  @override
  String get chooseQRType => 'Elige el tipo de código QR que quieres crear';

  @override
  String get qrFormWebsiteUrl => 'URL del Sitio Web';

  @override
  String get qrFormWebsiteSubtitle => 'Crea un código QR que abra un sitio web';

  @override
  String get urlFieldLabel => 'URL del Sitio Web';

  @override
  String get urlFieldPlaceholder => 'https://ejemplo.com';

  @override
  String get continueButton => 'Continuar';

  @override
  String get urlValidationEmpty => 'Por favor ingresa una URL';

  @override
  String get urlValidationSpaces => 'La URL no puede contener espacios';

  @override
  String get urlValidationInvalid => 'Por favor ingresa una URL válida';

  @override
  String get urlValidationDomain => 'Por favor ingresa un dominio válido';

  @override
  String get customizeQR => 'Personaliza tu QR';

  @override
  String get customizeQRSubtitle => 'Haz único tu código QR';

  @override
  String get foregroundColor => 'Color Principal';

  @override
  String get backgroundColor => 'Color de Fondo';

  @override
  String get eyeColor => 'Color de Ojos';

  @override
  String get qrSize => 'Tamaño';

  @override
  String get templates => 'Plantillas';

  @override
  String get logo => 'Logo';

  @override
  String get addLogo => 'Agregar Logo';

  @override
  String get removeLogo => 'Quitar Logo';

  @override
  String get preview => 'Vista Previa';

  @override
  String get generateQR => 'Generar QR';

  @override
  String get qrFormCompleteFields =>
      'Completa todos los campos correctamente para continuar';

  @override
  String get qrFormStepEnterInfo => 'Ingresa información';

  @override
  String get qrFormStepCustomize => 'Personalizar apariencia';

  @override
  String get qrFormStepPreviewSave => 'Vista previa y guardar';

  @override
  String get qrFormButtonContinue => 'Continuar';

  @override
  String get qrFormButtonPreview => 'Vista Previa';

  @override
  String get qrFormButtonSave => 'Guardar Código QR';

  @override
  String get generateQRTitle => 'Generar QR';

  @override
  String get generateQRSubtitle => 'Crea códigos QR para varios propósitos';

  @override
  String get templateLibrary => 'Biblioteca de Plantillas';

  @override
  String get templateLibraryDescription =>
      'Explora plantillas de QR prediseñadas';

  @override
  String get qrTypePersonalInfo => 'Información Personal';

  @override
  String get qrTypePersonalInfoDesc => 'Detalles de contacto\nFormato vCard';

  @override
  String get qrTypeWebsiteUrl => 'URL del Sitio Web';

  @override
  String get qrTypeWebsiteUrlDesc => 'Enlaces a sitios web\ny páginas web';

  @override
  String get qrTypeWifi => 'Red WiFi';

  @override
  String get qrTypeWifiDesc => 'Comparte credenciales\nWiFi fácilmente';

  @override
  String get qrTypeText => 'Mensaje de Texto';

  @override
  String get qrTypeTextDesc =>
      'Contenido de texto plano\npara cualquier propósito';

  @override
  String get qrTypeEmail => 'Correo Electrónico';

  @override
  String get qrTypeEmailDesc => 'Envía correo con\ncontenido pre-llenado';

  @override
  String get qrTypeLocation => 'Ubicación';

  @override
  String get qrTypeLocationDesc => 'Coordenadas GPS\ny puntos del mapa';
}
