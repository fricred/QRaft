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