// lib/services/nfc_service.dart

import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  Function(String peerId, String peerName)? _onInviteReceived;

  void startSession(Function(String, String) onInviteReceived) {
    _onInviteReceived = onInviteReceived;

    NfcManager.instance.isAvailable().then((available) {
      if (!available) return;

      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) return;

            final cachedMessage = ndef.cachedMessage;
            if (cachedMessage == null || cachedMessage.records.isEmpty) return;

            final payloadBytes = cachedMessage.records.first.payload;
            final payload = utf8.decode(payloadBytes.skip(3).toList()); // Skip language code bytes
            final json = jsonDecode(payload);

            final peerId = json['id'] ?? 'unknown';
            final peerName = json['name'] ?? 'unknown';

            _onInviteReceived?.call(peerId, peerName);
          } catch (e) {
            // Silently fail or log error
          }
        },
      );
    });
  }

  void stopSession() {
    NfcManager.instance.stopSession();
  }

  Future<void> sendInvite(String deviceId, String displayName) async {
    final ndefRecord = NdefRecord.createText(jsonEncode({
      "id": deviceId,
      "name": displayName,
    }));

    final message = NdefMessage([ndefRecord]);
    // await NfcManager.instance.writeNdef(message);
  }
}
