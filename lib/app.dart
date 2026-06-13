import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/theme.dart';
import 'screens/splash/splash_screen.dart';

class WeightNestApp extends StatelessWidget {
  const WeightNestApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          return SafeArea(
            top: false,
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
