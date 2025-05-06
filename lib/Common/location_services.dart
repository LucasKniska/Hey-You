import 'dart:async';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../Data/repositories/user/user_repository.dart';

class LocationController extends GetxController {
  Rx<Position?> currentPosition = Rx<Position?>(null);
  late StreamSubscription<Position> _subscription;

  @override
  Future<void> onInit() async {
    super.onInit();

    bool granted = await requestLocationPermission();

    _subscription = Geolocator.getPositionStream().listen((pos) {
      currentPosition.value = pos;
    });

    // 🔁 Listen and trigger backend updates
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
    // Replace with Firestore/REST/etc.
    Get.put(UserRepository());

    UserRepository.instance.updateUserField(currentUser, 'location', {'lat': pos.latitude, 'long': pos.longitude});

    currentUser.location = {
      'lat': pos.latitude,
      'long': pos.longitude
    };

    // Example: Firestore
    // await FirebaseFirestore.instance.collection("Users").doc(userId).update({
    //   "location": {"lat": pos.latitude, "lon": pos.longitude}
    // });

    // Or your own API
    // await http.post(Uri.parse('https://your.api/location'), body: {
    //   "lat": pos.latitude.toString(),
    //   "lon": pos.longitude.toString(),
    // });
  }
}
