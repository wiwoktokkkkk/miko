import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:miko/src/security/security_service.dart';

void main() {
  test('status keamanan memiliki pesan blokir yang jelas', () {
    for (final reason in [
      'root',
      'vpn',
      'proxy',
      'analyzer',
      'instrumentation',
      'debugger',
      'emulator',
      'signature',
      'unavailable',
    ]) {
      final status = SecurityStatus.blocked(reason);
      expect(status.isSecure, isFalse);
      expect(status.title, isNotEmpty);
      expect(status.message, isNotEmpty);
    }
  });

  test(
    'platform test non-Android tidak memanggil pemeriksaan native',
    () async {
      expect(Platform.isAndroid, isFalse);
      final status = await SecurityService.instance.refresh();
      expect(status.isSecure, isTrue);
      expect(status.reason, 'secure');
    },
  );
}
