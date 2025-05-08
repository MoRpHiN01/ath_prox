import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';

void initializeService() {
  FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationTitle: "ATH PROXIMITY",
      notificationContent: "Running in background",
      notificationIcon: 'resource_icon',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );
}

void onStart(ServiceInstance service) {
  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (!(await service.isRunning())) timer.cancel();

    final wifiInfo = await WifiService().getWifiDetails();
    // BLE scan could be initiated here
  });
}