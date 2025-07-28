import 'package:equatable/equatable.dart';

abstract class QRDataModel extends Equatable {
  String get qrData;
  String get displayText;
}

class PersonalInfoData extends QRDataModel {
  final String firstName;
  final String lastName;
  final String organization;
  final String jobTitle;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String note;

  PersonalInfoData({
    required this.firstName,
    required this.lastName,
    this.organization = '',
    this.jobTitle = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.note = '',
  });

  @override
  String get qrData {
    final vcard = StringBuffer('BEGIN:VCARD\n');
    vcard.writeln('VERSION:3.0');
    vcard.writeln('FN:$firstName $lastName');
    vcard.writeln('N:$lastName;$firstName;;;');
    
    if (organization.isNotEmpty) {
      vcard.writeln('ORG:$organization');
    }
    if (jobTitle.isNotEmpty) {
      vcard.writeln('TITLE:$jobTitle');
    }
    if (phone.isNotEmpty) {
      vcard.writeln('TEL:$phone');
    }
    if (email.isNotEmpty) {
      vcard.writeln('EMAIL:$email');
    }
    if (website.isNotEmpty) {
      vcard.writeln('URL:$website');
    }
    if (address.isNotEmpty) {
      vcard.writeln('ADR:;;$address;;;;');
    }
    if (note.isNotEmpty) {
      vcard.writeln('NOTE:$note');
    }
    
    vcard.writeln('END:VCARD');
    return vcard.toString();
  }

  @override
  String get displayText => '$firstName $lastName${organization.isNotEmpty ? ' - $organization' : ''}';

  @override
  List<Object?> get props => [firstName, lastName, organization, jobTitle, phone, email, website, address, note];
}

class URLData extends QRDataModel {
  final String url;

  URLData({required this.url});

  @override
  String get qrData => url.startsWith('http') ? url : 'https://$url';

  @override
  String get displayText => url;

  @override
  List<Object?> get props => [url];
}

class WiFiData extends QRDataModel {
  final String networkName;
  final String password;
  final String security; // WPA, WEP, or empty for open
  final bool hidden;

  WiFiData({
    required this.networkName,
    required this.password,
    this.security = 'WPA',
    this.hidden = false,
  });

  @override
  String get qrData {
    return 'WIFI:T:$security;S:$networkName;P:$password;H:${hidden ? 'true' : 'false'};;';
  }

  @override
  String get displayText => 'WiFi: $networkName';

  @override
  List<Object?> get props => [networkName, password, security, hidden];
}

class TextData extends QRDataModel {
  final String text;

  TextData({required this.text});

  @override
  String get qrData => text;

  @override
  String get displayText => text.length > 50 ? '${text.substring(0, 50)}...' : text;

  @override
  List<Object?> get props => [text];
}

class EmailData extends QRDataModel {
  final String email;
  final String subject;
  final String body;

  EmailData({
    required this.email,
    this.subject = '',
    this.body = '',
  });

  @override
  String get qrData {
    final uri = StringBuffer('mailto:$email');
    final params = <String>[];
    
    if (subject.isNotEmpty) {
      params.add('subject=${Uri.encodeComponent(subject)}');
    }
    if (body.isNotEmpty) {
      params.add('body=${Uri.encodeComponent(body)}');
    }
    
    if (params.isNotEmpty) {
      uri.write('?${params.join('&')}');
    }
    
    return uri.toString();
  }

  @override
  String get displayText => 'Email: $email${subject.isNotEmpty ? ' - $subject' : ''}';

  @override
  List<Object?> get props => [email, subject, body];
}

class LocationData extends QRDataModel {
  final double latitude;
  final double longitude;
  final String? name;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  @override
  String get qrData => 'geo:$latitude,$longitude${name != null ? '?q=$latitude,$longitude(${Uri.encodeComponent(name!)})' : ''}';

  @override
  String get displayText => name ?? 'Location: $latitude, $longitude';

  @override
  List<Object?> get props => [latitude, longitude, name];
}

/// Colombian Tax Information for Electronic Billing
class ColombianTaxInfoData extends QRDataModel {
  final String documentType;      // CC, NIT, TI, CE, PP
  final String documentNumber;    // Document number
  final String fullName;          // Full name or business name
  final String businessName;      // Razón social (for companies)
  final String address;           // Full address
  final String city;              // City/Municipality
  final String cityCode;          // DANE city code
  final String department;        // Department/State
  final String departmentCode;    // DANE department code
  final String postalCode;        // ZIP code
  final String phone;             // Phone number
  final String email;             // Email for billing
  final String taxRegime;         // Régimen tributario
  final List<String> taxResponsibilities; // Responsabilidades fiscales
  final String economicActivity;  // Actividad económica
  final String verificationDigit; // Dígito de verificación (for NIT)

  ColombianTaxInfoData({
    required this.documentType,
    required this.documentNumber,
    required this.fullName,
    this.businessName = '',
    required this.address,
    required this.city,
    this.cityCode = '',
    required this.department,
    this.departmentCode = '',
    this.postalCode = '',
    required this.phone,
    required this.email,
    this.taxRegime = 'Común',
    this.taxResponsibilities = const [],
    this.economicActivity = '',
    this.verificationDigit = '',
  });

  @override
  String get qrData {
    // Generate vCard format with Colombian tax extensions
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:$fullName');
    if (businessName.isNotEmpty) {
      buffer.writeln('ORG:$businessName');
    }
    buffer.writeln('TEL:$phone');
    buffer.writeln('EMAIL:$email');
    buffer.writeln('ADR:;;$address;$city;$department;$postalCode;Colombia');
    
    // Colombian tax-specific fields (custom extensions)
    buffer.writeln('X-CO-DOC-TYPE:$documentType');
    buffer.writeln('X-CO-DOC-NUMBER:$documentNumber');
    if (verificationDigit.isNotEmpty) {
      buffer.writeln('X-CO-VERIFICATION-DIGIT:$verificationDigit');
    }
    buffer.writeln('X-CO-TAX-REGIME:$taxRegime');
    if (taxResponsibilities.isNotEmpty) {
      buffer.writeln('X-CO-TAX-RESPONSIBILITIES:${taxResponsibilities.join(",")}');
    }
    if (economicActivity.isNotEmpty) {
      buffer.writeln('X-CO-ECONOMIC-ACTIVITY:$economicActivity');
    }
    if (cityCode.isNotEmpty) {
      buffer.writeln('X-CO-CITY-CODE:$cityCode');
    }
    if (departmentCode.isNotEmpty) {
      buffer.writeln('X-CO-DEPARTMENT-CODE:$departmentCode');
    }
    
    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  @override
  String get displayText {
    final type = documentType == 'NIT' ? 'Empresa' : 'Persona';
    final name = businessName.isNotEmpty ? businessName : fullName;
    return '$type: $name ($documentType: $documentNumber)';
  }

  @override
  List<Object?> get props => [
        documentType,
        documentNumber,
        fullName,
        businessName,
        address,
        city,
        cityCode,
        department,
        departmentCode,
        postalCode,
        phone,
        email,
        taxRegime,
        taxResponsibilities,
        economicActivity,
        verificationDigit,
      ];
}