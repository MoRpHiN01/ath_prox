
import 'dart:async';
import 'package:flutter/foundation.dart';

class SessionRefreshManager with ChangeNotifier {
  final Duration _defaultInterval = const Duration(seconds: 10);
  Timer? _refreshTimer;
  bool _autoRefreshEnabled = true;
  Duration _refreshInterval;
  VoidCallback? onRefresh;

  SessionRefreshManager({Duration? refreshInterval})
      : _refreshInterval = refreshInterval ?? const Duration(seconds: 10);

  bool get isAutoRefreshEnabled => _autoRefreshEnabled;
  Duration get refreshInterval => _refreshInterval;

  void start({VoidCallback? onRefreshCallback}) {
    onRefresh = onRefreshCallback;
    _refreshTimer?.cancel();
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(_refreshInterval, (_) {
        if (onRefresh != null) {
          onRefresh!();
          notifyListeners();
        }
      });
    }
  }

  void stop() {
    _refreshTimer?.cancel();
    notifyListeners();
  }

  void setRefreshInterval(Duration interval) {
    _refreshInterval = interval;
    restart();
  }

  void toggleAutoRefresh(bool enable) {
    _autoRefreshEnabled = enable;
    restart();
  }

  void restart() {
    stop();
    start(onRefreshCallback: onRefresh);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
