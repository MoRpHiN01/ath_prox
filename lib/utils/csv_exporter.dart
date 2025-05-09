import '../models/session_record.dart';

class CSVExporter {
  static String export(List<SessionRecord> records) {
    final buffer = StringBuffer("Peer,Start Time,End Time,Duration\n");
    for (var r in records) {
      buffer.writeln("\${r.peerName},\${r.startTime},\${r.endTime},\${r.duration.inMinutes} min");
    }
    return buffer.toString();
  }
}