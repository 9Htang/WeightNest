import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() {
    runApp(const WeightNestApp());
  }, (error, stack) {
    debugPrint('STARTUP_ERROR: $error\n$stack');
  });
}
