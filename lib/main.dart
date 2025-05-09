import 'package:flutter/material.dart';
import 'screens/report_screen.dart';
import 'services/session_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final SessionManager sessionManager = SessionManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATH PROXIMITY - GET CONNECTED',
      home: ReportScreen(sessionManager),
    );
  }
}