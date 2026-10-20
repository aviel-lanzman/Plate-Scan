import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_services.dart';
import 'screens/home_screen.dart';
import 'util/app_name.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The camera-to-OCR rotation math assumes a portrait UI.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(PlateScanApp(services: AppServices()));
}

class PlateScanApp extends StatelessWidget {
  const PlateScanApp({super.key, required this.services});

  final AppServices services;

  static const _seed = Color(0xFF0038B8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (_) => appName(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('he', 'IL'),
      supportedLocales: const [Locale('he', 'IL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(colorSchemeSeed: _seed),
      darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark),
      home: HomeScreen(services: services),
    );
  }
}
