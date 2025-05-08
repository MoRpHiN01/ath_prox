// lib/widgets/session_timer.dart

import 'dart:async';
import 'package:flutter/material.dart';

class SessionTimer extends StatefulWidget {
  final DateTime startTime;

  const SessionTimer({super.key, required this.startTime});

  @override
  State<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<SessionTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String format(Duration d) {
    return d.toString().split('.').first.padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.timer, size: 16),
        const SizedBox(width: 4),
        Text("Time: ${format(_elapsed)}"),
      ],
    );
  }
}
