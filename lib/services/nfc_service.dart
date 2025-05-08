import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcService {
  Future<void> startNfcSession(Function(String id) onDiscovered) async {
    try {
      var tag = await FlutterNfcKit.poll();
      if (tag.id.isNotEmpty) {
        onDiscovered(tag.id);
      }
    } catch (e) {
      print("NFC error: \$e");
    } finally {
      await FlutterNfcKit.finish();
    }
  }
}