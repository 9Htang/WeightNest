import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/connect/connect_screen.dart';
import 'widgets/connection_status_bar.dart';
import 'desktop/desktop_layout.dart';

class WeightNestApp extends StatelessWidget {
  const WeightNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    return ProviderScope(
      child: MaterialApp(
        title: 'WeightNest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          if (isDesktop) return child;
          return SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: child,
                  ),
                ),
                ConnectionStatusBar(
                  onConnect: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ConnectScreen())),
                ),
              ],
            ),
          );
        },
        home: isDesktop ? const DesktopLayout() : const SplashScreen(),
      ),
    );
  }
}
