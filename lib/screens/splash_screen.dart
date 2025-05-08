// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../services/user_model.dart';
import '../utils/logger_setup.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _logger = logger;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Load user preferences
    final userModel = Provider.of<UserModel>(context, listen: false);
    await userModel.loadPrefs();

    // Prompt for display name if still default
    if (userModel.displayName == 'User') {
      final name = await _askDisplayName();
      if (name != null && name.trim().isNotEmpty) {
        await userModel.setDisplayName(name.trim());
      }
    }

    // Request necessary permissions
    await _requestPermissions();

    // Brief splash delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Navigate to HomeScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<String?> _askDisplayName() async {
    String? result;
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter your display name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'e.g. Alice'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Use Default'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((value) => result = value);
    return result;
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();

    statuses.forEach((permission, status) {
      _logger.i('Permission $permission: $status');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
