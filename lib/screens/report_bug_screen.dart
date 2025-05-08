import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({Key? key}) : super(key: key);

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _submitBugReport() async {
    final String subject = Uri.encodeComponent("Bug Report: ${_titleController.text}");
    final String body = Uri.encodeComponent(_descriptionController.text);
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'jira@getconnected.co.za',
      query: 'subject=$subject&body=$body',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open email client.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report a Bug")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Bug Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Bug Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitBugReport,
              icon: const Icon(Icons.bug_report),
              label: const Text("Submit Report"),
            )
          ],
        ),
      ),
    );
  }
}
