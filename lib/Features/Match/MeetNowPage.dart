import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Data/models/CurrentMatch.dart';

class MeetingNowScreen extends StatelessWidget {
  final CurrentMatch current;

  const MeetingNowScreen({super.key, required this.current});

  @override
  Widget build(BuildContext context) {

    print(current);

    final userLocations = current.userData
        .map<LatLng>((user) => LatLng(user.location['lat']!, user.location['long']!))
        .toList();

    final List<Marker> markers = current.userData.map<Marker>((user) {
      final lat = user.location['lat']!;
      final long = user.location['long']!;
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(lat, long),
        child: const Icon(Icons.location_pin, color: Colors.red),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Now!'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: userLocations[0],
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                if (userLocations.length >= 2) {
                  final origin = userLocations[0];
                  final destination = userLocations[1];
                  final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch directions')),
                    );
                  }
                }
              },
              child: const Text('Get Directions'),
            ),
          ),
        ],
      ),
    );
  }
}
