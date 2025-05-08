import 'package:flutter/material.dart';
import 'package:proximity/utils/device_info.dart';
import 'package:proximity/utils/email_sender.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final deviceInfo = await DeviceInfo.getSummary();
    final message = '''
${_controller.text}

-----
Device Info:
$deviceInfo
''';

    final success = await EmailSender.sendSupportEmail(
      subject: "ATH PROXIMITY Support Request",
      body: message,
    );

    setState(() => _sending = false);
    final snackBar = SnackBar(
      content: Text(success ? 'Support request sent!' : 'Failed to send email.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Support")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Describe your issue below:"),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                maxLines: 6,
                validator: (val) =>
                    val != null && val.trim().isNotEmpty ? null : "Required",
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Type your issue here...",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _sending
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                onPressed: _sending ? null : _submitSupportRequest,
                label: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}