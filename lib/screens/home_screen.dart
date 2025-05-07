// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../widgets/app_drawer.dart';
import '../widgets/session_invite_bubble.dart';
import '../models/user_model.dart';
import '../models/session.dart';
import '../services/ble_service.dart';
import '../services/session_sync_service.dart';
import '../services/network_discovery_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bleService = BleService();
  final _blePeripheral = FlutterBlePeripheral();
  final _netDisc = NetworkDiscoveryService();
  final _instanceId = const Uuid().v4();

  late UserModel _user;
  late StreamSubscription<List<ScanResult>> _scanSub;

  bool _isAdvertising = false;
  bool _initialized = false;

  final Map<String, _PeerData> _peers = {};
  RawDatagramSocket? _inviteSocket;  // listens for UDP invites


  /// Show incoming invite dialog (UDP or BLE)
  void _showIncomingInvite(String name, String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionInviteBubble(
        deviceName: name,
        onAccept: () => _handleResponse(_peers[id]!, true),
        onDecline: () => _handleResponse(_peers[id]!, false),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndStart();
  }

  Future<void> _requestPermissionsAndStart() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final sdk = info.version.sdkInt ?? 0;
      List<Permission> perms = [];
      if (sdk < 31) {
        perms.add(Permission.locationWhenInUse);
      } else {
        perms.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]);
      }
      final status = await perms.request();
      if (status.values.any((s) => !s.isGranted)) {
        Fluttertoast.showToast(msg: 'Required permissions missing');
        return;
      }
    }
    _startBleScan();
  }

  void _startBleScan() {
    _bleService.startScan();
    _scanSub = _bleService.scanResults.listen(_onBleResults);
  }

  void _onBleResults(List<ScanResult> results) {
    for (final r in results) {
      final adv = r.advertisementData.manufacturerData;
      if (!adv.containsKey(0xFF)) continue;
      try {
        final map = jsonDecode(utf8.decode(adv[0xFF]!)) as Map<String, dynamic>;
        // BLE fallback invite
        if (map['type']=='invite' && map['targetId']==_instanceId) {
        final fromName = map['from'] as String? ?? map['instanceId'] as String;
        _addOrUpdatePeer(map['instanceId'] as String, fromName, source: 'ble');
        _showIncomingInvite(fromName, map['instanceId'] as String);
        continue;
          continue;
        }
        final peerId = map['instanceId'] as String?;
        final name = map['user'] as String?;
        if (peerId==null || peerId==_instanceId) continue;
        _addOrUpdatePeer(peerId, name??peerId, source:'ble');
      } catch (_) {}
    }
  }

  void _addOrUpdatePeer(String id, String name, {required String source, String? ip}) {
    final existing = _peers[id];
    if (existing==null) {
      _peers[id] = _PeerData(id:id,name:name,ip:ip);
    } else {
      existing.name = name;
      if (source=='wifi' && ip!=null) existing.ip = ip;
    }
    setState((){});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _user = Provider.of<UserModel>(context);
      if (_user.displayName.trim().isNotEmpty) {
        _netDisc.onPeerFound = (ip,name,senderId) {
          if (senderId!=_instanceId) _addOrUpdatePeer(senderId,name,source:'wifi',ip:ip);
        };
        _netDisc.start(_user.displayName);

        // Listen for UDP invite packets
        RawDatagramSocket.bind(InternetAddress.anyIPv4, NetworkDiscoveryService.port).then((socket) {
          _inviteSocket = socket;
          socket.broadcastEnabled = true;
          socket.listen((event) {
            if (event == RawSocketEvent.read) {
              final dg = socket.receive();
              if (dg == null) return;
              try {
                final msg = utf8.decode(dg.data);
                final map = jsonDecode(msg) as Map<String, dynamic>;
                if (map['type'] == 'invite' && map['targetId'] == _instanceId) {
                  final fromName = map['from'] as String? ?? '';
                  final senderId = map['instanceId'] as String?;
                  if (senderId != null && senderId != _instanceId) {
                    _addOrUpdatePeer(senderId, fromName, source: 'wifi', ip: dg.address.address);
                    _showIncomingInvite(fromName, senderId);
                  }
                }
              } catch (_) {}
            }
          });
        });
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _scanSub.cancel();
    _bleService.stopScan();
    _blePeripheral.stop();
    _netDisc.stop();
    _inviteSocket?.close();
    super.dispose();
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(()=>_isAdvertising=false);
      Fluttertoast.showToast(msg:'Stopped advertising');
    } else {
      final payload={'user':_user.displayName,'instanceId':_instanceId};
      await _blePeripheral.start(
        advertiseData:AdvertiseData(
          manufacturerId:0xFF,
          manufacturerData:Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        ),
      );
      setState(()=>_isAdvertising=true);
      Fluttertoast.showToast(msg:'Started advertising');
    }
  }

  Future<void> _sendUdpInvite(_PeerData peer) async {
    final payload=jsonEncode({
      'type':'invite',
      'from':_user.displayName,
      'instanceId':_instanceId,
      'sessionId':peer.id,
      'targetId':peer.id,
    });
    final socket=await RawDatagramSocket.bind(InternetAddress.anyIPv4,0);
    socket.send(utf8.encode(payload),InternetAddress(peer.ip!),NetworkDiscoveryService.port);
    socket.close();
  }

  Future<void> _bleFallbackInvite(_PeerData peer) async {
    final payload=jsonEncode({
      'type':'invite',
      'from':_user.displayName,
      'instanceId':_instanceId,
      'sessionId':peer.id,
      'targetId':peer.id,
      'status':'pending',
    });
    await _blePeripheral.start(
      advertiseData:AdvertiseData(
        manufacturerId:0xFF,
        manufacturerData:Uint8List.fromList(utf8.encode(payload)),
      ),
    );
    Future.delayed(const Duration(seconds:5),() async {
      final restore=jsonEncode({'user':_user.displayName,'instanceId':_instanceId,'status':'available'});
      await _blePeripheral.start(
        advertiseData:AdvertiseData(
          manufacturerId:0xFF,
          manufacturerData:Uint8List.fromList(utf8.encode(restore)),
        ),
      );
    });
  }

  void _invitePeer(_PeerData peer) {
    if (peer.status=='pending'||peer.status=='connected') return;
    setState(()=>peer.status='pending');
    if (peer.ip!=null) {
      _sendUdpInvite(peer).catchError((_)=>_bleFallbackInvite(peer));
    } else {
      _bleFallbackInvite(peer);
    }
    showDialog(
      context:context,
      barrierDismissible:false,
      builder:(_)=>SessionInviteBubble(
        deviceName:peer.name,
        onAccept:(){Navigator.of(context).pop();_handleResponse(peer,true);},
        onDecline:(){Navigator.of(context).pop();_handleResponse(peer,false);},
      ),
    );
  }

  void _handleResponse(_PeerData peer,bool accepted) {
    final now=DateTime.now();
    setState((){
      peer.status=accepted?'connected':'declined';
      peer.startTime=accepted?now:null;
    });
    SessionSyncService.syncSessions([
      Session(
        sessionId:now.millisecondsSinceEpoch.toString(),
        deviceId:peer.id,
        deviceName:peer.name,
        startTime:now,
        status:accepted?SessionStatus.accepted:SessionStatus.declined,
      )
    ]);
    Fluttertoast.showToast(msg:accepted?'Connected to ${peer.name}':'Declined ${peer.name}');
  }

  void _refresh() {
    _peers.clear();
    _bleService.startScan();
    Fluttertoast.showToast(msg:'Refreshing peers...');
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    final nameSet=_user.displayName.trim().isNotEmpty;
    return Scaffold(
      appBar:AppBar(
        title:Text(nameSet?'Welcome, ${_user.displayName}':'Set Display Name'),
        actions:[IconButton(icon:const Icon(Icons.refresh),onPressed:_refresh)],
      ),
      drawer:AppDrawer(onNavigate:(route){Navigator.of(context).pop();if(ModalRoute.of(context)!.settings.name!=route)Navigator.of(context).pushReplacementNamed(route);}),
      body:nameSet
          ?Column(children:[
            const SizedBox(height:8),
            ElevatedButton(onPressed:_toggleAdvertising,child:Text(_isAdvertising?'Stop Advertising':'Start Advertising')),
            Expanded(child:
              _peers.isEmpty
                ?const Center(child:Text('No peers found.'))
                :ListView(children:_peers.values.map((peer){
                  return ListTile(
                    leading:CircleAvatar(backgroundColor:peer.status=='connected'?Colors.blue:peer.status=='pending'?Colors.amber:Colors.grey,radius:8),
                    title:Text(peer.name),
                    subtitle:peer.status=='connected'&&peer.startTime!=null?Text('Timer: ${_format(peer.startTime!)}'):Text('Status: ${peer.status}'),
                    trailing:ElevatedButton(onPressed:()=>_invitePeer(peer),child:Text(peer.status=='connected'?'End':'Invite')),
                  );
                }).toList(),
              )
            ),
          ])
          :Center(child:ElevatedButton(onPressed:()=>Navigator.of(context).pushNamed('/profile'),child:const Text('Set Your Name'))),
    );
  }

  String _format(DateTime start){final d=DateTime.now().difference(start);String two(int n)=>n.toString().padLeft(2,'0');return '${d.inHours}:${two(d.inMinutes%60)}:${two(d.inSeconds%60)}';}
}

class _PeerData{String id;String name;String status;DateTime? startTime;String? ip;_PeerData({required this.id,required this.name,this.status='available',this.startTime,this.ip});}
