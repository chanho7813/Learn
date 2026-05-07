import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LearnApp());
}

class LearnApp extends StatefulWidget {
  const LearnApp({super.key});

  @override
  State<LearnApp> createState() => _LearnAppState();
}

class _LearnAppState extends State<LearnApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final dark = await SettingsService.getDarkMode();
    setState(() => _darkMode = dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0D9488),
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF0D9488),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onThemeChanged: _loadTheme),
    );
  }
}
