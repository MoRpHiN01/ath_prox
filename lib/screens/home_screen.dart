import 'package:flutter/material.dart';
import '../widgets/advertising_toggle_button.dart';
import '../services/ble_service.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  late UserModel _user;
  bool _isAdvertising = false;

  @override
  void initState() {
    super.initState();
    _user = UserModel(displayName: 'Unknown'); // Replace with actual user fetch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATH PROXIMITY - GET CONNECTED'),
        actions: [
          AdvertisingToggleButton(
            isAdvertising: _isAdvertising,
            onToggle: () async {
              if (_isAdvertising) {
                await _bleService.stopAdvertising();
              } else {
                await _bleService.startAdvertising(_user.displayName, 'available');
              }

              setState(() {
                _isAdvertising = !_isAdvertising;
              });
            },
          ),
        ],
      ),
      body: const Center(child: Text('Device List Goes Here')),
    );
  }
}
