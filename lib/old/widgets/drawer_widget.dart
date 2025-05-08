import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundImage: user.profileImagePath.isNotEmpty
                  ? Image.asset(user.profileImagePath).image
                  : const AssetImage('assets/images/logo.png'),
            ),
            accountName: Text(user.displayName),
            accountEmail: const Text("Tap to manage profile"),
            onDetailsPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
            decoration: const BoxDecoration(
              color: Color(0xFF003366), // Brand color
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text("Support"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/support');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
          ),

          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text("Exit"),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
