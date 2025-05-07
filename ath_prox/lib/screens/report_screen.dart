// lib/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../services/session_sync_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Session> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final result = await SessionSyncService.getSyncedSessions();
    setState(() {
      sessions = result;
      isLoading = false;
    });
  }

  String _formatTime(DateTime dt) {
    return DateFormat('yyyy-MM-dd – HH:mm').format(dt);
  }

  Color _statusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.accepted:
        return Colors.green;
      case SessionStatus.declined:
        return Colors.red;
      case SessionStatus.pending:
        return Colors.amber;
      case SessionStatus.completed:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadSessions();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(child: Text('No sessions recorded yet.'))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final duration = session.endTime != null
                        ? session.endTime!.difference(session.startTime).inMinutes
                        : 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(session.status),
                          child: Icon(
                            Icons.devices,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(session.deviceName.isNotEmpty
                            ? session.deviceName
                            : "Unknown Device"),
                        subtitle: Text(
                          'Start: ${_formatTime(session.startTime)}\n'
                          'End: ${session.endTime != null ? _formatTime(session.endTime!) : "Ongoing"}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$duration min',
                                style: const TextStyle(fontSize: 12)),
                            Text(session.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(session.status),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
