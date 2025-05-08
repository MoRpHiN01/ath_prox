import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';

class AppDrawer extends StatelessWidget {
  final Function(String route) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF003366)),
            accountName: Text(user.displayName),
            accountEmail: Text(user.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user.profileImagePath.isNotEmpty
                  ? Image.asset(user.profileImagePath).image
                  : const AssetImage('assets/images/logo.png'),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () => onNavigate('/'),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () => onNavigate('/profile'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () => onNavigate('/settings'),
                ),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Reports'),
                  onTap: () => onNavigate('/reports'),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () => onNavigate('/about'),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Support / Report Bug'),
                  onTap: () => onNavigate('/support'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Exit'),
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
