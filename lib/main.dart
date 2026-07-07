import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/app_clock.dart';
import 'core/debug_log_sink.dart';
import 'plugins/plugins.dart';
import 'services/license_service.dart';
import 'services/notification_service.dart';

void main() async {
  if (kDebugMode) {
    DebugLogSink.install();
  }
  WidgetsFlutterBinding.ensureInitialized();
  await AppClock.restore();
  registerPlugins();
  try {
    await LicenseService().init();
  } catch (_) {}
  await NotificationService.instance.init();

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
