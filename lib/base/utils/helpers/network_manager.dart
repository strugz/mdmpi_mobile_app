import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final RxBool isOnline = true.obs;

  /// Initialize the network manager and set up a stream to continually check the connection status.
  @override
  void onInit() {
    super.onInit();
    initConnectivity();
  }

  Future<void> initConnectivity() async {
    isOnline.value = await isConnected();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      isOnline.value = !result.contains(ConnectivityResult.none);
    });
  }

  /// Check the internet connection status.
  ///   Returns `true` if connected, `false` otherwise
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result.contains(ConnectivityResult.none)) {
        isOnline.value = false;
        return false;
      } else {
        isOnline.value = true;
        return true;
      }
    } on PlatformException catch (_) {
      isOnline.value = false;
      return false;
    }
  }

  /// Dispose or close the active connectivity stream.
  @override
  void onClose() {
    super.onClose();
    _connectivitySubscription.cancel();
  }
}
