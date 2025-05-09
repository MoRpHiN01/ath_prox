import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATH PROXIMITY - GET CONNECTED',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('ATH PROXIMITY')),
        body: Center(child: Text('Hello, ATH Proximity!')),
      ),
    );
  }
}
