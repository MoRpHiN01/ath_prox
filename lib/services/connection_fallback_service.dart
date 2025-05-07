import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ConnectionFallbackService {
  static Future<void> tryNfcExchange({
    required String userName,
    required VoidCallback onSuccess,
    required VoidCallback onFail,
  }) async {
    try {
      NFCTag tag = await FlutterNfcKit.poll();
      await FlutterNfcKit.transceive(jsonEncode({"user": userName}));
      await FlutterNfcKit.finish();
      Fluttertoast.showToast(msg: "NFC session established");
      onSuccess();
    } catch (e) {
      debugPrint("NFC Fallback Error: $e");
      onFail();
    }
  }

  static Future<void> tryWifiDirect({
    required String userName,
    required VoidCallback onSuccess,
    required VoidCallback onFail,
  }) async {
    try {
      bool isConnected = await WiFiForIoTPlugin.isConnected();
      if (!isConnected) {
        await WiFiForIoTPlugin.connect("ATH_PROXIMITY_WIFI", password: "proximity123");
      }
      if (await WiFiForIoTPlugin.isConnected()) {
        Fluttertoast.showToast(msg: "WiFi Fallback connected");
        onSuccess();
      } else {
        onFail();
      }
    } catch (e) {
      debugPrint("WiFi Fallback Error: $e");
      onFail();
    }
  }
}
