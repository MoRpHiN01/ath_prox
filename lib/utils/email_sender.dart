import 'package:url_launcher/url_launcher.dart';

class EmailSender {
  static Future<bool> sendSupportEmail({required String subject, required String body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'help@getconnected.co.za',
      query: Uri.encodeFull('subject=$subject&body=$body'),
    );
    return await canLaunchUrl(uri) && await launchUrl(uri);
  }
}