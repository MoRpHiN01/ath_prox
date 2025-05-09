
import 'dart:io';

class WifiService {
  Future<void> sendBroadcast(String message) async {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 4444).then((socket) {
      socket.broadcastEnabled = true;
      socket.send(message.codeUnits, InternetAddress('255.255.255.255'), 4444);
    });
  }
}
