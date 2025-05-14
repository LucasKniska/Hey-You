import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hey_you/utils/constants/connection_parameters.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

import '../../Common/navigation_menu.dart';
import '../../Common/topbar.dart';
import '../../Data/models/CurrentMatch.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/sizes.dart';
import '../ViewConnections/ContactsPage.dart';
import 'MatchCompleteSpashScreen/ConnectedLineSplashScreen.dart';
import 'controllers/meetNow_controller.dart';

class MeetNowPage extends StatefulWidget {
  final Map<String, dynamic> userLocation;
  final Map<String, dynamic> otherUserLocation;
  final CurrentMatch current;

  const MeetNowPage({
    Key? key,
    required this.userLocation,
    required this.otherUserLocation,
    required this.current,
  }) : super(key: key);

  @override
  State<MeetNowPage> createState() => _MeetNowPageState();
}

class _MeetNowPageState extends State<MeetNowPage> {

  final MeetNowController _pageController = MeetNowController();

  GoogleMapController? _controller;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  int _distanceMeters = 0;
  bool _loading = true;

  bool _closePage = false;

  String userAddress = '';
  String otherUserAddress = '';

  late LatLng userLatLng = LatLng(
    widget.userLocation['lat'],
    widget.userLocation['long'],
  );

  late LatLng otherUserLatLng = LatLng(
    widget.otherUserLocation['lat'],
    widget.otherUserLocation['long'],
  );

  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _matchSubscription;

  @override
  void initState() {
    super.initState();

    _matchSubscription = FirebaseFirestore.instance
        .collection('Matches')
        .doc(widget.current.id)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted) {
        setState(() {
          _closePage = true;
        });
        return;
      };

      final current = CurrentMatch.fromJson(snapshot.data()!);

      final LatLng newUserLatLng;
      final LatLng newOtherUserLatLng;

      if (currentUser.id == current.userData[0].id) {
        newUserLatLng = LatLng(
          current.userData[0].location['lat']!,
          current.userData[0].location['long']!,
        );
        newOtherUserLatLng = LatLng(
          current.userData[1].location['lat']!,
          current.userData[1].location['long']!,
        );
      } else {
        newUserLatLng = LatLng(
          current.userData[1].location['lat']!,
          current.userData[1].location['long']!,
        );
        newOtherUserLatLng = LatLng(
          current.userData[0].location['lat']!,
          current.userData[0].location['long']!,
        );
      }

      if (userLatLng != newUserLatLng || otherUserLatLng != newOtherUserLatLng) {
        setState(() {
          userLatLng = newUserLatLng;
          otherUserLatLng = newOtherUserLatLng;
        });

        await _loadEverything();
      }
    });
  }

  @override
  void dispose() {
    _matchSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(_closePage){

      if(_pageController.connected){
        return ConnectedCircleSplashScreen(
          onFinish: () {
            Get.back();
          },
        );
      } else {
        Get.back();
      }
    }

    return Scaffold(
      appBar: TopBar(backArrow: true),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLatLng,
              zoom: 14,
            ),
            onMapCreated: (controller) async {
              _controller = controller;
              await _loadEverything();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (!_loading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ignore: prefer_single_quotes
                      Text("From: $userAddress"),
                      Text('To: $otherUserAddress'),
                      Text('Distance: ${(_distanceMeters / 1000).toStringAsFixed(2)} km'),

                      (_distanceMeters < TConnectionParameters.distanceToConnection) ?

                        Column(
                          children: [
                            const SizedBox(height: TSizes.spaceBtwItems), // spacing before button

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _pageController.confirmMeeting();
                                },
                                child: const Text('Connection Achieved?'),
                              ),
                            ),
                          ],
                        ) : SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }

  Future<void> _loadEverything() async {

    // Only show the loading progress indicator on the first load
    if(_loading == true) setState(() => _loading = true);

    final directions = await _getDirections();
    final polylinePoints = directions['polyline'];
    final distance = directions['distance'];

    final placemarks1 = await placemarkFromCoordinates(userLatLng.latitude, userLatLng.longitude);
    final placemarks2 = await placemarkFromCoordinates(otherUserLatLng.latitude, otherUserLatLng.longitude);
    final address1 = _formatPlacemark(placemarks1.first);
    final address2 = _formatPlacemark(placemarks2.first);

    if (!mounted) return;

    setState(() {
      _distanceMeters = distance;
      userAddress = address1;
      otherUserAddress = address2;

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 6,
          points: polylinePoints,
        )
      };

      _markers = {
        Marker(
          markerId: const MarkerId('other'),
          position: otherUserLatLng,
          infoWindow: InfoWindow(title: 'Other', snippet: address2),
        )
      };

      _loading = false;
    });

    final bounds = LatLngBounds(
      southwest: LatLng(
        userLatLng.latitude < otherUserLatLng.latitude ? userLatLng.latitude : otherUserLatLng.latitude,
        userLatLng.longitude < otherUserLatLng.longitude ? userLatLng.longitude : otherUserLatLng.longitude,
      ),
      northeast: LatLng(
        userLatLng.latitude > otherUserLatLng.latitude ? userLatLng.latitude : otherUserLatLng.latitude,
        userLatLng.longitude > otherUserLatLng.longitude ? userLatLng.longitude : otherUserLatLng.longitude,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  String _formatPlacemark(Placemark p) {
    return '${p.street}, ${p.locality}';
  }

  Future<Map<String, dynamic>> _getDirections() async {
    final response = await http.post(
      Uri.parse('https://api.openrouteservice.org/v2/directions/foot-walking/geojson'),
      headers: {
        'Authorization': '5b3ce3597851110001cf62485e57c931c3c44434884dd6f55fcf479a',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'coordinates': [
          [userLatLng.longitude, userLatLng.latitude],
          [otherUserLatLng.longitude, otherUserLatLng.latitude],
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Directions failed: ${response.body}');
    }

    final data = jsonDecode(response.body);

    final features = data['features'];
    if (features == null || features.isEmpty) {
      throw Exception('No features returned in GeoJSON response');
    }

    final geometry = features[0]['geometry'];
    final coords = geometry['coordinates'] as List;

    final polyline = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    final distance = features[0]['properties']['segments'][0]['distance'];

    return {
      'polyline': polyline,
      'distance': distance.toInt(),
    };
  }
}
