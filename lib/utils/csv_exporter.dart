import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CsvExporter {
  Future<String> exportSessionData(List<Map<String, dynamic>> sessions) async {
    final dir = await getExternalStorageDirectory();
    final path = "${dir?.path}/session_report.csv";
    final file = File(path);

    List<String> csvLines = ["Date,Start Time,End Time,Duration,Peer"];
    for (var session in sessions) {
      csvLines.add("\${session['date']},\${session['start']},\${session['end']},\${session['duration']},\${session['peer']}");
    }

    await file.writeAsString(csvLines.join("\n"));
    return path;
  }
}