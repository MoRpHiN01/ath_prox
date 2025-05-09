import 'package:telephony/telephony.dart';

class GsmService {
  final Telephony telephony = Telephony.instance;

  Future<String> getNetworkOperator() async {
    final info = await telephony.requestPhonePermissions ?? false;
    if (!info) return 'Permission denied';
    final operator = await telephony.carrierId;
    return operator ?? 'Unknown';
  }
}