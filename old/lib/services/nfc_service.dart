// lib/services/nfc_service.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/peer.dart';

class NfcService {
  static final String instanceId = const Uuid().v4();

  final void Function(Peer) onPeerDetected;
  final void Function(Object)? onError;

  bool _isSessionRunning = false;

  NfcService({
    required this.onPeerDetected,
    this.onError,
  });

  Future<void> startSession() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        throw Exception('NFC not available on this device.');
      }

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || ndef.cachedMessage == null) return;

            final record = ndef.cachedMessage!.records.first;
            final payload = utf8.decode(record.payload.skip(3).toList()); // Skip language code

            final map = jsonDecode(payload) as Map<String, dynamic>;
            final peer = Peer(
              instanceId: map['instanceId'],
              displayName: map['displayName'],
              status: map['status'],
            );
            onPeerDetected(peer);
          } catch (e) {
            onError?.call(e);
          }
        },
      );

      _isSessionRunning = true;
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> stopSession() async {
    if (_isSessionRunning) {
      await NfcManager.instance.stopSession();
      _isSessionRunning = false;
    }
  }

  Future<void> pushInvite(Peer peer) async {
    try {
      final jsonStr = jsonEncode({
        'instanceId': instanceId,
        'displayName': peer.displayName,
        'status': 'invite',
      });

      final payload = Uint8List.fromList(utf8.encode(jsonStr));
      final record = NdefRecord.createText(jsonStr);

      final message = NdefMessage([record]);

      await NfcManager.instance.writeNdef(message);
    } catch (e) {
      onError?.call(e);
    }
  }
}
