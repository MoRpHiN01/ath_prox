// lib/screens/support_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../widgets/app_drawer.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserModel>(context, listen: false);
    _nameCtrl.text = user.displayName;
    if (user.email != null) _emailCtrl.text = user.email!;
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return {
        'platform': 'Android',
        'model': info.model,
        'version': info.version.release,
        'manufacturer': info.manufacturer,
        'device': info.device,
      };
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return {
        'platform': 'iOS',
        'model': info.utsname.machine,
        'systemVersion': info.systemVersion,
        'deviceName': info.name,
      };
    }
    return {'platform': 'Unknown'};
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final deviceInfo = await _getDeviceInfo();
      await FirebaseFirestore.instance.collection('support_requests').add({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
      });
      Fluttertoast.showToast(msg: "Support request submitted");
      _formKey.currentState!.reset();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error submitting request: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _launchWhatsApp() async {
    const phone = "+27824604953";
    final message = Uri.encodeComponent("Hi, I need help with ATH Proximity...");
    final whatsappUrl = Uri.parse("https://wa.me/$phone?text=$message");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(msg: "Could not open WhatsApp");
    }
  }

  void _handleNavigation(String route) {
    Navigator.of(context).pop(); // close drawer
    if (ModalRoute.of(context)!.settings.name != route) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      drawer: AppDrawer(onNavigate: _handleNavigation),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(labelText: "Subject"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _messageCtrl,
                decoration: const InputDecoration(labelText: "Message"),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitSupportRequest,
                icon: const Icon(Icons.send),
                label: Text(_isSubmitting ? "Submitting..." : "Submit"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.chat),
                label: const Text("Contact via WhatsApp"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
