// lib/services/nfc_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:logger/logger.dart';
import '../models/peer.dart';

class NfcService {
  final Logger _log = Logger();
  final void Function(Peer peer) onPeerReceived;

  NfcService({required this.onPeerReceived});

  Future<void> startNfcSession(String instanceId, String displayName, String status) async {
    try {
      _log.i("Starting NFC session...");
      final Peer localPeer = Peer(
        instanceId: instanceId,
        displayName: displayName,
        status: status,
      );
      final String payload = jsonEncode({
        'instanceId': localPeer.instanceId,
        'displayName': localPeer.displayName,
        'status': localPeer.status,
      });
      final NFCTag tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 10));

      if (tag.type == NFCTagType.iso7816 || tag.type == NFCTagType.iso15693 || tag.type == NFCTagType.mifare_ultralight) {
        await FlutterNfcKit.transceive(payload);
        _log.i("NFC payload sent");
      } else {
        _log.w("Unsupported NFC tag type");
      }
    } catch (e) {
      _log.e("NFC session error: $e");
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  Future<void> listenForNfcPeer() async {
    try {
      _log.i("Listening for NFC peer...");
      final NFCTag tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 15));
      final String response = await FlutterNfcKit.transceive("GET");
      final Map<String, dynamic> map = jsonDecode(response);
      final peer = Peer(
        instanceId: map['instanceId'],
        displayName: map['displayName'],
        status: map['status'],
      );
      _log.i("Received peer via NFC: ${peer.displayName}");
      onPeerReceived(peer);
    } catch (e) {
      _log.e("NFC listen error: $e");
    } finally {
      await FlutterNfcKit.finish();
    }
  }
}
