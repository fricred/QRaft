import 'package:flutter_test/flutter_test.dart';
import 'package:qraft/features/dynamic_qr/presentation/dq_ui.dart';

void main() {
  test('own domain and shorteners are caught before checkout (mirrors the server)', () {
    expect(dynamicUrlProblem('scanqraft.app/abc'), 'own_domain_not_allowed');
    expect(dynamicUrlProblem('https://scanqraft.app/k7m2qx9p/'), 'own_domain_not_allowed');
    expect(dynamicUrlProblem('https://scanqraft.app'), isNull);
    expect(dynamicUrlProblem('https://www.scanqraft.app/tienda'), isNull);
    expect(dynamicUrlProblem('https://bit.ly/x'), 'shortener_not_allowed');
    expect(dynamicUrlProblem('tinyurl.com/abc'), 'shortener_not_allowed');
    expect(dynamicUrlProblem('https://minegocio.com/menu'), isNull);
    expect(dynamicUrlProblem('https://notbit.ly.example.com'), isNull);
  });
}
