import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  // flutter_secure_storage needs the binding before any platform channel call.
  // https://pub.dev/packages/flutter_secure_storage#installation
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BChatApp());
}
