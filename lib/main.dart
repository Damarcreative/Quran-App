import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // --bg-color
        primaryColor: const Color(0xFF40B779), // --accent-green
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF40B779),
          surface: Color(0xFF0A0A0A),
          onSurface: Colors.white,
          outline: Color(0xFF2A2A2A), // --border-color
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
