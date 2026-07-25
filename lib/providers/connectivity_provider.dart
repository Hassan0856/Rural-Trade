import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityNotifier extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityNotifier() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !_isOffline(results);
    
    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty || results.every((result) => result == ConnectivityResult.none);
  }
}

final connectivityProvider = ChangeNotifierProvider<ConnectivityNotifier>((ref) {
  return ConnectivityNotifier();
});
