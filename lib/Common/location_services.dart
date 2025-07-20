import 'dart:async';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hey_you/Data/models/UserModel.dart';

import '../Data/repositories/user/user_repository.dart';

class LocationController extends GetxController {
  Rx<Position?> currentPosition = Rx<Position?>(null);
  late StreamSubscription<Position> _subscription;

  @override
  Future<void> onInit() async {
    super.onInit();

    bool _ = await requestLocationPermission();

    _subscription = Geolocator.getPositionStream().listen((Position pos) {
      currentPosition.value = pos;
    });

    ever(currentPosition, (Position? pos) {
      if (pos != null) {
        _updateBackend(pos);
      }
    });
  }


  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }

  Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are off — you may want to show a dialog here
      return false;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // Ask if denied
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // If permanently denied, navigate user to settings
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    // All good
    return true;
  }


  Future<void> _updateBackend(Position pos) async {

    final UserModel currentUser = UserRepository.instance.currentUser;

    // TODO: If location did not change enough
    if(currentUser.location['lat'] == pos.latitude && currentUser.location['long'] == pos.longitude) return;

    currentUser.location = <String, double>{
      'lat': pos.latitude,
      'long': pos.longitude
    };

    UserRepository.instance.updateLocation(pos);

  }
}
