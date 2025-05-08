import 'package:flutter/material.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({Key? key}) : super(key: key);

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final TextEditingController _bugController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendBugReport() async {
    setState(() => _isSending = true);

    final body = _bugController.text.trim();
    final subject = "ATH PROXIMITY - Bug Report";

    // This can be replaced with actual backend submission logic or mailto
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jira@getconnected.co.za',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    await launchUrl(emailLaunchUri);

    setState(() {
      _isSending = false;
      _bugController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report a Bug")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Describe the issue below:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _bugController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: "What went wrong?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.bug_report),
              label: _isSending ? const CircularProgressIndicator() : const Text("Send Report"),
              onPressed: _isSending ? null : _sendBugReport,
            )
          ],
        ),
      ),
    );
  }
}
