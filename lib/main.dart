import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/security/security_service.dart';
import 'src/state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter menyembunyikan pesan build error dan hanya menggambar layar abu-abu
  // pada mode release. Jika masih ada kasus perangkat-spesifik, tampilkan pesan
  // yang dapat difoto/dilaporkan alih-alih membuat pengguna terjebak di layar
  // kosong tanpa petunjuk.
  ErrorWidget.builder = (details) => ErrorWidget.withDetails(
    message:
        'Miko gagal menampilkan halaman ini.\n\n${details.exceptionAsString()}',
    error: details.exception is FlutterError
        ? details.exception as FlutterError
        : null,
  );

  await SecurityService.instance.refresh();
  await AppStore.init();
  runApp(const MikoApp());
}
