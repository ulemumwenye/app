import 'package:flutter/material.dart';
import 'package:secure_application/secure_application.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart'; // Import the home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final darkMode = preferences.getBool('darkMode') ?? false;

  runApp(MyApp(darkMode: darkMode));
}

class MyApp extends StatelessWidget {
  final bool darkMode;
  const MyApp({Key? key, required this.darkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SecureApplication(
      nativeRemoveDelay: 800, // Optional: Adjust delay as needed
      onNeedUnlock: (secureApplicationController) async {
        // Handle unlock logic if needed (e.g., biometric authentication)
        // For now, we'll just unlock immediately
        secureApplicationController?.authSuccess(unlock: true);
        return null;
      },
      child: MaterialApp(
        title: 'Nation Online',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
        home: SecureGate(
          blurr: 20, // Optional: Adjust blur intensity
          opacity: 0.5, // Optional: Adjust opacity
          child: HomeScreen(darkMode: darkMode),
        ),
      ),
    );
  }
}
