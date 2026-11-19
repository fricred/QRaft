import 'package:equatable/equatable.dart';

/// Shipping address collected on ShippingScreen.
///
/// Field names match the JSON keys accepted by the create_order Postgres RPC
/// (p_shipping JSONB parameter), so [toJson] can be passed directly to the
/// Edge Function body.
class ShippingAddress extends Equatable {
  const ShippingAddress({
    required this.recipientName,
    required this.phone,
    required this.department,
    required this.city,
    required this.address,
    this.notes,
  });

  /// Full name of the package recipient.
  final String recipientName;

  /// Colombian phone number. The UI enforces +57 prefix.
  /// Example: +573001234567
  final String phone;

  /// DANE departamento name. Example: "Cundinamarca"
  final String department;

  /// DANE municipio name. Example: "Bogotá D.C."
  final String city;

  /// Street address. Example: "Calle 123 #45-67 Apto 8"
  final String address;

  /// Optional delivery notes. Example: "Apartamento 302, timbre no funciona"
  final String? notes;

  /// Serialize to the JSON shape expected by the create_order RPC and the
  /// create-payment-intent Edge Function.
  /// Keys use snake_case to match the PostgreSQL p_shipping JSONB spec.
  Map<String, dynamic> toJson() => {
        'recipient_name': recipientName,
        'phone': phone,
        'department': department,
        'city': city,
        'address': address,
        'notes': notes,
      };

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      ShippingAddress(
        recipientName: json['recipient_name'] as String,
        phone: json['phone'] as String,
        department: json['department'] as String,
        city: json['city'] as String,
        address: json['address'] as String,
        notes: json['notes'] as String?,
      );

  @override
  List<Object?> get props => [
        recipientName,
        phone,
        department,
        city,
        address,
        notes,
      ];
}
