
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  void startNfcSession(Function(String) onDataReceived) {
    NfcManager.instance.startSession(onDiscovered: (tag) async {
      final data = tag.data.toString();
      onDataReceived(data);
    });
  }

  void stopNfcSession() {
    NfcManager.instance.stopSession();
  }
}
