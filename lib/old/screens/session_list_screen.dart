// lib/screens/session_list_screen.dart

import 'package:flutter/material.dart';
import '../models/session.dart';

class SessionListScreen extends StatelessWidget {
  final List<Session> sessions;

  const SessionListScreen({super.key, required this.sessions});

  String formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, "0");
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
      (prev, session) => prev + session.duration,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Logs'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blueGrey.shade50,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            child: Text(
              "Total Time in Sessions: ${formatDuration(totalDuration)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: sessions.isEmpty
                ? const Center(child: Text("No sessions recorded."))
                : ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final duration = session.duration;

                      return ListTile(
                        title: Text(session.deviceName.isNotEmpty
                            ? session.deviceName
                            : "Unknown Device"),
                        subtitle: Text(
                          "From: ${session.startTime}\n"
                          "To: ${session.endTime ?? "Ongoing"}",
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${duration.inMinutes} min"),
                            Text(
                              session.status.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _statusColor(session.status),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
}
