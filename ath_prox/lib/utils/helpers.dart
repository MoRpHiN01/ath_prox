// lib/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Shows a snackbar if context is available; falls back to toast if not
void showToast(BuildContext context, String message, {bool fallbackToToast = true}) {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (_) {
    if (fallbackToToast) {
      Fluttertoast.showToast(msg: message);
    }
  }
}

/// Restarts the app (only works reliably on Android)
void restartApp() {
  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
}
