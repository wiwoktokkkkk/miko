import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.init();
  runApp(const MikoApp());
}
