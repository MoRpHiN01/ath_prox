import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _actualNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _currentStatus = 'Available';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _displayNameController.text = prefs.getString('displayName') ?? '';
    _actualNameController.text = prefs.getString('actualName') ?? '';
    _emailController.text = prefs.getString('email') ?? '';
    setState(() {
      _currentStatus = prefs.getString('status') ?? 'Available';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', _displayNameController.text.trim());
    await prefs.setString('actualName', _actualNameController.text.trim());
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('status', _currentStatus);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: _actualNameController,
              decoration: const InputDecoration(labelText: 'Actual Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
            DropdownButtonFormField<String>(
              value: _currentStatus,
              items: ['Available', 'Busy', 'Do Not Disturb']
                  .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _currentStatus = value);
              },
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Save Profile')),
          ],
        ),
      ),
    );
  }
}
