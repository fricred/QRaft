import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/qr_generator/presentation/widgets/content_inputs.dart';

void main() {
  test('Photon results become places (name, detail, coordinates)', () {
    const body = '{"features":['
        '{"geometry":{"coordinates":[-74.0628,4.6486]},"properties":{"name":"Parque de la 93","street":"Calle 93A","city":"Bogotá","country":"Colombia"}},'
        '{"geometry":{"coordinates":[-75.5,6.2]},"properties":{"street":"Carrera 43A","housenumber":"1-50","city":"Medellín","country":"Colombia"}},'
        '{"geometry":{"coordinates":[]},"properties":{"name":"sin coordenadas"}}]}';
    final places = PhotonGeocoder.parsePhoton(body);
    expect(places, hasLength(2));
    expect(places[0].name, 'Parque de la 93');
    expect(places[0].detail, 'Calle 93A, Bogotá, Colombia');
    expect(places[0].lat, 4.6486);
    expect(places[0].lng, -74.0628);
    expect(places[1].name, 'Carrera 43A 1-50');
    expect(places[1].label, 'Carrera 43A 1-50, Medellín, Colombia');
    expect(PhotonGeocoder.parsePhoton('not json'), isEmpty);
  });

  test('event date round-trips in the editor format', () {
    final d = DateTime(2026, 11, 22, 19, 5);
    expect(formatEventDate(d), '2026-11-22 19:05');
    expect(parseEventDate('2026-11-22 19:05'), d);
    expect(parseEventDate('22/11/2026'), isNull);
  });
}
