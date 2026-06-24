import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/trip_provider.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WasteGlassApp());
}

class WasteGlassApp extends StatelessWidget {
  const WasteGlassApp({super.key});

  static const Color deepGreen = Color(0xFF005B49);
  static const Color darkGreen = Color(0xFF003E34);
  static const Color mintBackground = Color(0xFFEAF7F2);
  static const Color softMint = Color(0xFFCFEBDD);
  static const Color accentGreen = Color(0xFF64E863);
  static const Color ink = Color(0xFF071426);
  static const Color muted = Color(0xFF73838B);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: deepGreen,
      brightness: Brightness.light,
    );

    return ChangeNotifierProvider(
      create: (_) => TripProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Waste Glass Collection',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme.copyWith(
            primary: deepGreen,
            secondary: accentGreen,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: mintBackground,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: mintBackground,
            foregroundColor: ink,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFD8E8E1)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD8E8E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: deepGreen, width: 1.5),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: deepGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFDDE7E3),
              disabledForegroundColor: const Color(0xFF7B8B92),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: deepGreen,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              side: const BorderSide(color: deepGreen, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}
