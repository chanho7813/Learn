import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WordUpApp());
}

class WordUpApp extends StatefulWidget {
  const WordUpApp({super.key});

  @override
  State<WordUpApp> createState() => _WordUpAppState();
}

class _WordUpAppState extends State<WordUpApp> {
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
      title: 'WordUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onThemeChanged: _loadTheme),
    );
  }
}
