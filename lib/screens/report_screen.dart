
// lib/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  Future<void> _sendBugReportEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jira@getconnected.co.za',
      queryParameters: {
        'subject': 'Bug Report - ATH PROXIMITY',
        'body': 'Please describe the issue encountered, including steps to reproduce, expected outcome, and actual outcome.

Device Info:
- Platform: Android/iOS
- App Version: x.y.z
- User ID: [auto-filled or user provided]

Details:
',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Bug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use this screen to report a bug directly to the development team.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bug_report),
                label: const Text('Send Bug Report'),
                onPressed: () => _sendBugReportEmail(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
