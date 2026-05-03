import 'package:flutter/material.dart';

/// Términos y Condiciones screen (Spanish).
///
/// Covers Ley 1480 Art. 47 retracto exemption for personalized products,
/// 3-month warranty, payment/IVA terms, and applicable law.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Términos y condiciones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Semantics(
        identifier: 'terms_screen',
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('Términos y Condiciones de Uso'),
              _buildSubheader('QRaft · Colombia'),
              const SizedBox(height: 8),
              _buildBodyText('Última actualización: 1 de mayo de 2026'),
              const SizedBox(height: 24),

              // 1. Objeto
              _buildSectionTitle('1. Objeto del servicio'),
              _buildBodyText(
                'QRaft es una plataforma de diseño y grabado láser de códigos QR '
                'personalizados. Los usuarios pueden:\n\n'
                '• Crear códigos QR para URLs, información personal, WiFi, vCards, '
                'eventos y ubicaciones\n'
                '• Personalizar el diseño visual de sus QRs\n'
                '• Encargar el grabado láser de sus QRs en materiales como madera, '
                'acrílico, metal, cuero, vidrio y piedra\n\n'
                'El servicio es operado por QRaft desde Colombia.',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // 2. Proceso de compra
              _buildSectionTitle('2. Proceso de compra y pago'),
              _buildBodyText(
                'Los pagos se realizan en pesos colombianos (COP) a través de Wompi S.A.S., '
                'aceptando tarjetas de crédito/débito, PSE, Nequi y Daviplata.\n\n'
                'Todos los precios incluyen IVA del 19% según la normativa tributaria '
                'colombiana vigente.\n\n'
                'El pedido se confirma una vez verificado el pago por Wompi. '
                'QRaft enviará confirmación por correo electrónico con el número de orden.',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // 3. Exclusión retracto
              _buildSectionTitle(
                  '3. Productos personalizados — Exclusión del derecho de retracto'),
              _buildWarningBox(
                'AVISO IMPORTANTE: Los productos de QRaft son fabricados bajo las '
                'especificaciones personalizadas del cliente (diseño único de QR grabado). '
                'En consecuencia, están EXCLUIDOS del derecho de retracto de 5 días hábiles '
                'conforme al Artículo 47, numeral 3 de la Ley 1480 de 2011 '
                '(Estatuto del Consumidor de Colombia).\n\n'
                'Al confirmar tu compra, aceptas esta exclusión.',
              ),
              const SizedBox(height: 12),
              _buildBodyText(
                'La exclusión aplica porque cada QR grabado es único e intransferible: '
                'el contenido, diseño visual y material son configurados por el usuario '
                'antes de la producción, haciendo imposible la reventa del producto.',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // 4. Garantía
              _buildSectionTitle('4. Garantía (Ley 1480 Art. 7-11)'),
              _buildBodyText(
                'Todos los productos QRaft cuentan con garantía de 3 meses (90 días) '
                'contra defectos de fabricación y problemas de escaneabilidad contados '
                'desde la fecha de entrega.\n\n'
                'La garantía cubre:\n'
                '• Defectos de grabado que impidan la lectura del QR\n'
                '• Materiales defectuosos no evidentes al momento de la entrega\n\n'
                'La garantía NO cubre:\n'
                '• Daño causado por uso inadecuado, caídas o accidentes\n'
                '• Pérdida del objeto\n'
                '• Desgaste normal por uso\n\n'
                'Para reclamar garantía: Perfil → Garantía 3 meses, o escríbenos a '
                'soporte@qraft.co indicando tu número de orden.',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // 5. Política de reembolsos
              _buildSectionTitle('5. Política de reembolsos'),
              _buildBodyText(
                'QRaft realizará reembolsos en los siguientes casos:\n\n'
                '• Producto defectuoso (verificado en el período de garantía)\n'
                '• Entrega de producto erróneo (diferente al pedido)\n'
                '• Pérdida del envío por parte del transportador (según política del '
                'operador logístico)\n\n'
                'No aplica reembolso por cambio de parecer del comprador dado que los '
                'productos son personalizados (ver sección 3).\n\n'
                'El reembolso se acreditará por el mismo medio de pago utilizado en '
                'un plazo máximo de 10 días hábiles desde la aprobación del reclamo.',
              ),
              const Divider(color: Color(0xFF3A3A3A), height: 32),

              // 6. Ley aplicable
              _buildSectionTitle('6. Ley aplicable y jurisdicción'),
              _buildBodyText(
                'Estos términos se rigen por las leyes de la República de Colombia, '
                'en particular por la Ley 1480 de 2011 (Estatuto del Consumidor), '
                'la Ley 1581 de 2012 (Habeas Data) y la Ley 527 de 1999 (Comercio '
                'Electrónico).\n\n'
                'Cualquier controversia será resuelta ante las autoridades competentes '
                'de Colombia. Para reclamaciones ante la Superintendencia de Industria '
                'y Comercio (SIC): www.sic.gov.co.',
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

  Widget _buildWarningBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFFB300), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
