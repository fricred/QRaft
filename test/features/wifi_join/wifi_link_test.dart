import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/wifi_join/wifi_join_screen.dart';

void main() {
  test('parses the qraft://wifi link built by the public page', () {
    final w = WifiLink.tryParse('qraft://wifi?ssid=Caf%C3%A9+Wi%3BFi&pw=p%26ss&sec=WPA&hidden=false')!;
    expect(w.ssid, 'Café Wi;Fi');
    expect(w.password, 'p&ss');
    expect(w.security, 'WPA');
    expect(w.hidden, isFalse);
    expect(w.isOpen, isFalse);
  });

  test('open network and invalid links', () {
    expect(WifiLink.tryParse('qraft://wifi?ssid=Lobby&pw=&sec=nopass&hidden=true')!.isOpen, isTrue);
    expect(WifiLink.tryParse('qraft://wifi?pw=x'), isNull);
    expect(WifiLink.tryParse('qraft://auth/verify?token=1'), isNull);
    expect(WifiLink.tryParse('https://wifi?ssid=x'), isNull);
  });
}
