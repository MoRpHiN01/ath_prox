// lib/screens/splash_screen.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final displayName = prefs.getString('preferredName') ?? '';
    final email = prefs.getString('email');
    final profilePath = prefs.getString('profileImagePath');

    final user = Provider.of<UserModel>(context, listen: false);
    user.updateDisplayName(displayName.isNotEmpty ? displayName : 'User');
    user.updateEmail(email);
    if (profilePath != null && profilePath.isNotEmpty) {
      user.updateProfileImage(File(profilePath));
    }

    if (displayName.isEmpty) {
      _promptForName();
    } else {
      _goToHome();
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _promptForName() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Welcome!"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Enter your display name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Use fallback
              _goToHome();
            },
            child: const Text("Skip"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('preferredName', name);
                Provider.of<UserModel>(context, listen: false).updateDisplayName(name);
              }
              Navigator.of(context).pop();
              _goToHome();
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 160),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "ATH > PROXIMITY > GET CONNECTED",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
