import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'plugins/plugins.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerPlugins();

  runZonedGuarded(() {
    runApp(const WeightNestApp());
  }, (error, stack) {
    debugPrint('STARTUP_ERROR: $error\n$stack');
  });
}
