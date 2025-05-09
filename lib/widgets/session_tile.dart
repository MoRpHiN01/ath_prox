import 'package:flutter/material.dart';
import '../models/session_record.dart';

class SessionTile extends StatelessWidget {
  final SessionRecord record;

  SessionTile(this.record);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(record.peerName),
      subtitle: Text("Duration: ${record.duration.inMinutes} min"),
    );
  }
}