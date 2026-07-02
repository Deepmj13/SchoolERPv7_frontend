import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  final controller = StreamController<bool>();

  connectivity.onConnectivityChanged.listen((results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    controller.add(isConnected);
  });

  connectivity.checkConnectivity().then((results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    controller.add(isConnected);
  });

  ref.onDispose(() => controller.close());
  return controller.stream;
});
