import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hey_you/Data/models/UserModel.dart';
import '../Data/repositories/user/user_repository.dart';

class LocationController extends GetxController {
  static LocationController get instance => Get.find();

  final Rx<Position?> currentPosition = Rx<Position?>(null);
  late StreamSubscription<Position> _subscription;
  Position? _lastBackendUpdatePosition;

  // Settings
  final double minDistance = 3; // meters
  final Duration locationUpdateInterval = const Duration(seconds: 3);

  @override
  Future<void> onInit() async {
    super.onInit();

    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return;

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // OS won't send updates if <10m change
    );

    _subscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) {
      currentPosition.value = pos;
    });

    ever(
      currentPosition,
          (Position? pos) {
        if (pos != null) {
          _maybeUpdateBackend(pos);
        }
      },
    );

    singleUpdate();
  }

  Future<void> _maybeUpdateBackend(Position pos) async {
    if (_lastBackendUpdatePosition == null ||
        Geolocator.distanceBetween(
          _lastBackendUpdatePosition!.latitude,
          _lastBackendUpdatePosition!.longitude,
          pos.latitude,
          pos.longitude,
        ) >= minDistance) {
      await _updateBackend(pos);
      _lastBackendUpdatePosition = pos;
    }
  }

  Future<void> _updateBackend(Position pos) async {
    final UserModel currentUser = UserRepository.instance.currentUser;

    currentUser.location = {
      'lat': pos.latitude,
      'long': pos.longitude,
    };

    await UserRepository.instance.updateLocation(pos);
  }

  Future<void> singleUpdate() async {
    print('Creating single update');
    currentPosition.value = await Geolocator.getCurrentPosition();
    print('Calling backend with: ${currentPosition.value}');
    _updateBackend(currentPosition.value!);
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}
