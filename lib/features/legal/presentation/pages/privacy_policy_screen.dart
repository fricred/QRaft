import 'package:flutter/material.dart';

/// Full Spanish privacy policy screen.
///
/// Covers all Ley 1581 de 2012 + Decreto 1377 de 2013 required elements.
/// Accessible from checkout, signup, and profile.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Política de privacidad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Semantics(
        identifier: 'privacy_policy_screen',
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                'Política de Privacidad y Tratamiento de Datos Personales',
              ),
              _buildSubheader(
                'Ley 1581 de 2012 · Decreto 1377 de 2013 · Colombia',
              ),
              const SizedBox(height: 8),
              _buildBodyText(
                'Última actualización: 1 de mayo de 2026',
              ),
              const SizedBox(height: 24),

              // Section 1
              _buildSectionTitle('1. Responsable del tratamiento'),
              _buildBodyText(
                'QRaft, operado por [Nombre legal de la empresa], con NIT [pendiente]. '
                'Correo de contacto: privacidad@qraft.co\n\n'
                'En esta política, "QRaft", "nosotros" o "la empresa" se refiere a la '
                'entidad responsable del tratamiento de sus datos personales.',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // Section 2
              _buildSectionTitle('2. Datos que recolectamos'),
              _buildBodyText(
                'Recolectamos y tratamos los siguientes datos personales:\n\n'
                '• Nombre completo y correo electrónico (registro y autenticación)\n'
                '• Dirección de envío (departamento, municipio, dirección) para entrega de productos físicos\n'
                '• Historial de QRs generados (tipos, contenido, configuración visual)\n'
                '• Historial de escaneos realizados desde la app\n'
                '• Fotografías de logo (si aplica, para personalización de QR)\n'
                '• Datos de pago: procesados exclusivamente por Wompi S.A.S. '
                '— QRaft no almacena números de tarjeta ni datos sensibles de pago\n'
                '• Información de dispositivo y uso de la aplicación (Firebase Analytics)',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // Section 3
              _buildSectionTitle('3. Finalidad del tratamiento'),
              _buildBodyText(
                'Sus datos personales son tratados con las siguientes finalidades:\n\n'
                '• Prestación del servicio de generación y gestión de QRs personalizados\n'
                '• Cumplimiento de pedidos de productos físicos (grabado láser)\n'
                '• Procesamiento de pagos a través de Wompi S.A.S.\n'
                '• Envío de comunicaciones transaccionales (confirmaciones de orden, '
                'cambios de estado, notificaciones de entrega)\n'
                '• Mejora del producto y análisis de uso (datos agregados y anonimizados)\n'
                '• Atención de PQRS (Peticiones, Quejas, Reclamos y Sugerencias)\n'
                '• Cumplimiento de obligaciones legales y regulatorias en Colombia',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // Section 4
              _buildSectionTitle(
                  '4. Derechos del titular (Ley 1581 de 2012)'),
              _buildBodyText(
                'Como titular de datos personales, usted tiene los siguientes derechos:\n\n'
                '• Acceso: conocer los datos personales que tratamos sobre usted\n'
                '• Rectificación: solicitar la corrección de datos inexactos o incompletos\n'
                '• Actualización: mantener sus datos al día\n'
                '• Supresión (derecho al olvido): solicitar la eliminación de sus datos '
                'cuando no sean necesarios para las finalidades del tratamiento, o cuando '
                'haya revocado el consentimiento\n'
                '• Revocatoria del consentimiento: retirar el consentimiento otorgado al '
                'tratamiento de sus datos, sin que ello afecte la licitud del tratamiento '
                'previo a la revocatoria\n'
                '• Queja ante la SIC: presentar queja ante la Superintendencia de Industria '
                'y Comercio si considera que sus derechos han sido vulnerados',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // Section 5
              _buildSectionTitle('5. Mecanismos para ejercer sus derechos'),
              _buildBodyText(
                'Puede ejercer sus derechos de las siguientes formas:\n\n'
                '• Correo electrónico: privacidad@qraft.co\n'
                '• In-app: Perfil → Mis datos personales → Solicitar exportación / '
                'Eliminar cuenta\n\n'
                'Tiempo de respuesta: 10 días hábiles para consultas, '
                '15 días hábiles para solicitudes de eliminación.\n\n'
                'Identificación requerida: para proteger su información, '
                'solicitaremos verificación de identidad antes de procesar cualquier '
                'solicitud relacionada con sus datos.',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // Section 6
              _buildSectionTitle(
                  '6. Terceros que procesan datos'),
              _buildBodyText(
                'Compartimos o transferimos datos con los siguientes proveedores '
                'de servicios, quienes están sujetos a sus propias políticas de '
                'privacidad y a acuerdos de confidencialidad con QRaft:\n\n'
                '• Firebase / Google LLC — autenticación, analytics, crashlytics '
                '(Política: policies.google.com/privacy)\n'
                '• Supabase Inc. — base de datos, almacenamiento, funciones en la nube '
                '(Política: supabase.com/privacy)\n'
                '• Wompi S.A.S. — procesamiento de pagos con tarjeta, PSE, Nequi, Daviplata '
                '(Política: wompi.co/politica-de-privacidad)\n'
                '• Google AdMob — publicidad in-app (usuarios de plan gratuito) '
                '(Política: policies.google.com/privacy)\n'
                '• RevenueCat Inc. — gestión de suscripciones in-app '
                '(Política: revenuecat.com/privacy)',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // Section 7
              _buildSectionTitle('7. Retención de datos'),
              _buildBodyText(
                '• Historial de escaneos y QRs generados: conservados mientras la cuenta '
                'esté activa, o hasta que el usuario solicite su eliminación\n'
                '• Datos de órdenes y pagos: conservados por el período mínimo exigido '
                'por la normativa tributaria colombiana (5 años) contados desde la fecha '
                'de la transacción\n'
                '• Cuenta eliminada: datos personales purgados en los 30 días siguientes '
                'a la solicitud, salvo aquellos requeridos por obligaciones legales\n'
                '• Datos de contacto PQRS: conservados por 2 años para trazabilidad',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // Section 8
              _buildSectionTitle('8. Vigencia y cambios a esta política'),
              _buildBodyText(
                'Esta política rige desde la fecha de su publicación (1 de mayo de 2026). '
                'Cambios materiales serán notificados in-app con al menos 15 días de '
                'antelación. El uso continuado de la aplicación después de la notificación '
                'constituye aceptación de la nueva política.\n\n'
                'Para preguntas o inquietudes sobre esta política, contáctenos en '
                'privacidad@qraft.co.',
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
  }

  Widget _buildSubheader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}
