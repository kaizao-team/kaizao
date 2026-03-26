import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class ConnectivityNotifier extends StateNotifier<NetworkStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier() : super(NetworkStatus.online) {
    _init();
  }

  void _init() {
    _connectivity.checkConnectivity().then((results) {
      if (!mounted) return;
      state = _mapResults(results);
    });
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      state = _mapResults(results);
    });
  }

  NetworkStatus _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, NetworkStatus>((ref) {
  return ConnectivityNotifier();
});
