
import 'package:flutter/material.dart';

class ReportBugScreen extends StatefulWidget {
  const ReportBugScreen({Key? key}) : super(key: key);

  @override
  _ReportBugScreenState createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_formKey.currentState?.validate() ?? false) {
      final description = _descriptionController.text;

      // TODO: Integrate with bug reporting system (e.g., JIRA or email)
      print("Bug Report Submitted: $description");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bug report submitted. Thank you!')),
      );
      _descriptionController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Bug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Describe the issue you encountered:'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter bug description...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitReport,
                child: const Text('Submit Bug Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
