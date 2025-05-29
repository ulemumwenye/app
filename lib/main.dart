import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart'; // Import the home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final darkMode = preferences.getBool('darkMode') ?? false;

  runApp(MyApp(initialDarkMode: darkMode));
}

class MyApp extends StatefulWidget {
  final bool initialDarkMode;
  const MyApp({Key? key, required this.initialDarkMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late bool _currentDarkMode; // To pass to HomeScreen

  @override
  void initState() {
    super.initState();
    _currentDarkMode = widget.initialDarkMode;
    _themeMode = _currentDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void _toggleThemeMode() async {
    setState(() {
      _currentDarkMode = !_currentDarkMode;
      _themeMode = _currentDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('darkMode', _currentDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nation Online',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomeScreen(
        darkMode: _currentDarkMode, // Pass current dark mode state
        onToggleTheme: _toggleThemeMode, // Pass the toggle function
      ),
    );
  }
}
