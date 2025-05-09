
import 'dart:convert';

class Peer {
  final String instanceId;
  final String displayName;
  final String status;

  Peer({required this.instanceId, required this.displayName, required this.status});

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
        instanceId: json['instanceId'],
        displayName: json['displayName'],
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'displayName': displayName,
        'status': status,
      };
}
