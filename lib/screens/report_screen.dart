import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../widgets/session_tile.dart';

class ReportScreen extends StatelessWidget {
  final SessionManager sessionManager;

  ReportScreen(this.sessionManager);

  @override
  Widget build(BuildContext context) {
    final records = sessionManager.records;
    return Scaffold(
      appBar: AppBar(title: Text("Session Report")),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) => SessionTile(records[index]),
      ),
    );
  }
}