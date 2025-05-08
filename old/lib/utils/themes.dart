// lib/utils/themes.dart

import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  primaryColor: const Color(0xFF003366),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF003366),
    brightness: Brightness.light,
  ),

  // AppBar styling
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF003366),
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

  // FAB styling
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF00AEEF),
    foregroundColor: Colors.white,
  ),

  // Input fields
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF003366)),
    ),
  ),

  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF003366),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),

  // Text styling
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
    labelLarge: TextStyle(color: Colors.black),
  ),
);
