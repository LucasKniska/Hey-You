import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hey_you/Features/Match/subwidgets/ConnectionAchievedButton.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

import '../../Common/topbar.dart';
import '../../Data/models/CurrentMatch.dart';
import '../../Data/repositories/matching/match_repository.dart';
import '../../Data/repositories/user/user_repository.dart';
import 'SplashScreens/MatchCompleteSpashScreen/ConnectedLineSplashScreen.dart';
import 'controllers/meetNow_controller.dart';

class MeetNowPage extends StatefulWidget {
  final CurrentMatch current;

  const MeetNowPage({
    Key? key,
    required this.current,
  }) : super(key: key);

  @override
  State<MeetNowPage> createState() => _MeetNowPageState();
}

class _MeetNowPageState extends State<MeetNowPage> {
  final currentUser = UserRepository.instance.currentUser;
  final userRepo = UserRepository.instance;
  final matchRepo = MatchRepository.instance;

  final MeetNowController _pageController = MeetNowController();

  late CurrentMatch currentMatch;

  GoogleMapController? _controller;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  int _distanceFeet = 0;
  bool _loading = true;

  bool _closePage = false;

  String userAddress = '';
  String otherUserAddress = '';

  late LatLng userLatLng;
  late LatLng otherUserLatLng;

  late Worker _matchListener;

  @override
  void initState() {
    super.initState();

    matchRepo.beenToMeetNowPage = true;

    final i = currentUser.id == widget.current.userData[0].id ? 0 : 1;
    userLatLng = LatLng(
      widget.current.userData[i].location['lat']!,
      widget.current.userData[i].location['long']!,
    );
    otherUserLatLng = LatLng(
      widget.current.userData[1 - i].location['lat']!,
      widget.current.userData[1 - i].location['long']!,
    );

    _matchListener = ever<CurrentMatch?>(
        MatchRepository.instance.currentMatchRx,
        (match) async {

          if (match == null) {
            setState(() {
              _closePage = true;
            });
            return;
          }

          final i = currentUser.id == match.userData[0].id ? 0 : 1;
          final newUserLatLng = LatLng(
            match.userData[i].location['lat']!,
            match.userData[i].location['long']!,
          );
          final newOtherUserLatLng = LatLng(
            match.userData[1 - i].location['lat']!,
            match.userData[1 - i].location['long']!,
          );

          print('This user reference is $i');

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
    _matchListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(_closePage){
      matchRepo.beenToMeetNowPage = false;
      if(userRepo.successfulMatch.value){
        print('Showing connected circle splash screen.');
        return ConnectedCircleSplashScreen(
          onFinish: () {
            Get.back();
            Get.back();
          },
        );
      } else {
        Get.back();
        return SizedBox.shrink();
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
                      Text('Distance: ${(_distanceFeet)} ft'),

                      ConnectionAchieved(pageController: _pageController, distance: _distanceFeet, userAddress: userAddress)
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

    print("LOADING AND GETTING DIRECTIONS");
    final directions = await _getDirections();
    final polylinePoints = directions['polyline'];
    final distance = directions['distance'];

    final placemarks1 = await placemarkFromCoordinates(userLatLng.latitude, userLatLng.longitude);
    final placemarks2 = await placemarkFromCoordinates(otherUserLatLng.latitude, otherUserLatLng.longitude);
    final address1 = _formatPlacemark(placemarks1.first);
    final address2 = _formatPlacemark(placemarks2.first);

    if (!mounted) return;

    setState(() {
      _distanceFeet = distance;
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
    });

    if (_loading) {
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
    setState(() {
      _loading = false;
    });
  }

  String _formatPlacemark(Placemark p) {
    return '${p.street}, ${p.locality}';
  }

  Future<Map<String, dynamic>> _getDirections() async {
    final response = await http.post(
      Uri.parse('https://api.openrouteservice.org/v2/directions/foot-walking/geojson'),
      headers: {
        'Authorization': '--rotated--',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'coordinates': [
          [userLatLng.longitude, userLatLng.latitude],
          [otherUserLatLng.longitude, otherUserLatLng.latitude],
        ]
      }),
    );

    print('Router API Response: ${response.body}');

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

    final distanceMeters = features[0]['properties']['segments'][0]['distance'];
    final distanceFeet = distanceMeters * 3.28084;

    return {
      'polyline': polyline,
      'distance': distanceFeet.toInt(),
    };
  }
}
