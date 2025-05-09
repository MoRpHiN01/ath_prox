import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ATH PROXIMITY")),
      body: Center(child: Text("Nearby Devices Will Appear Here")),
    );
  }
}