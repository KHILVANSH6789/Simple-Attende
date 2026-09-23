// ============================================================
// lib/main.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/storage/local_storage.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local storage
  await LocalStorage.init();

  runApp(const SimpleAttendeApp());
}
