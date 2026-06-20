import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'plugins/plugins.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerPlugins();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runZonedGuarded(() {
    runApp(const WeightNestApp());
  }, (error, stack) {
    debugPrint('STARTUP_ERROR: $error\n$stack');
  });
}
