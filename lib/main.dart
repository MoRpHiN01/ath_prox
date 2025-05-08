import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ATHProximityApp());
}

class ATHProximityApp extends StatelessWidget {
  const ATHProximityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATH PROXIMITY - GET CONNECTED',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}