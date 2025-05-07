// lib/screens/session_report_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/session.dart';

class SessionReportScreen extends StatefulWidget {
  const SessionReportScreen({super.key});

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  String _searchQuery = '';

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

  SessionStatus _parseStatus(String status) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => SessionStatus.pending,
    );
  }

  Future<void> _exportToCSV(List<QueryDocumentSnapshot> docs) async {
    try {
      final List<List<dynamic>> csvData = [
        ['Device Name', 'Status', 'Timestamp'],
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['deviceName'] ?? 'Unknown';
          final status = data['status'] ?? 'unknown';
          final timestamp =
              (data['timestamp'] as Timestamp).toDate().toIso8601String();
          return [name, status, timestamp];
        }),
      ];

      final csv = const ListToCsvConverter().convert(csvData);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/session_invites.csv');
      await file.writeAsString(csv);

      Share.shareXFiles([XFile(file.path)], text: 'Session Invite Logs');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Invite Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export as CSV',
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('session_invites')
                  .orderBy('timestamp', descending: true)
                  .get();
              await _exportToCSV(snapshot.docs);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Device Name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('session_invites')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading session invites.'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      data['deviceName']?.toString().toLowerCase() ?? '';
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No invites match the filter.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final deviceName = data['deviceName'] ?? 'Unknown';
                    final status = _parseStatus(data['status'] ?? 'pending');
                    final timestamp =
                        (data['timestamp'] as Timestamp).toDate();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(status),
                        radius: 6,
                      ),
                      title: Text(deviceName),
                      subtitle: Text(
                        'Status: ${status.name} • ${timestamp.toLocal()}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
