import 'package:flutter/material.dart';

/// BLE Constants
const int manufacturerId = 0xFF; // Common ID used for BLE advertising

/// Firestore Collections
const String kSessionCollection = 'sessions';
const String kSupportCollection = 'support_requests';
const String kSessionInvitesCollection = 'session_invites';

/// SharedPreferences Keys
const String kPrefDisplayName = 'user_display_name';
const String kPrefEmail = 'user_email';
const String kPrefRefreshRate = 'refreshRate';
const String kPrefDebugMode = 'debugMode';

/// App Theme Colors (based on logo)
const Color kPrimaryColor = Color(0xFF003366);
const Color kAmberStatus = Colors.amber;
const Color kRedStatus = Colors.red;
const Color kGreenStatus = Colors.green;
const Color kGreyStatus = Colors.grey;

/// Notification Channel
const String kNotificationChannelId = 'background_service_channel';

/// Debug
const bool isDevMode = bool.fromEnvironment('dart.vm.product') == false;

/// WhatsApp Support
const String kSupportPhone = "+27821234567";
