import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void restartApp() {
  if (Platform.isAndroid) {
    exit(0); // crude restart for Android — acceptable for POC/UAT
  } else {
    // TODO: Handle restart logic for iOS or Web if needed
  }
}

void showToast(BuildContext context, String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.black87,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}
