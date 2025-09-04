import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hey_you/Data/models/NearbyUser.dart';

import '../../../utils/constants/colors.dart';

class UsersNearMe extends StatelessWidget {
  final List<NearbyUser> users;

  const UsersNearMe({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No users near you. Move around to meet someone with Hey You!',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    users.sort((a, b) => a.distance.compareTo(b.distance));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          leading: Material(
            elevation: 1,
            shape: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(3), // Border thickness
              decoration: const BoxDecoration(
                color: Colors.white, // Border color
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: TColors.accent.withAlpha(255),
                child: Text(
                  users[index].username[0] + users[index].username[users[index].username.length-1],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            users[index].username,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(
            formatDistanceString(users[index].distance),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      },
    );
  }
}

String formatDistanceString(double distanceKm) {
  if (distanceKm < 1) {
    final meters = (distanceKm * 1000).round();
    return "${meters}m away";
  } else {
    return "${distanceKm.toStringAsFixed(1)}km away";
  }
}

