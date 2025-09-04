import 'package:flutter/material.dart';
import 'package:hey_you/Data/models/NearbyUser.dart';

import '../../../utils/constants/colors.dart';

class UsersNearMe extends StatelessWidget {
  final List<NearbyUser> users;
  final void Function(NearbyUser)? onTap;

  const UsersNearMe({super.key, required this.users, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No users near you. Move around to meet someone with Hey You!',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // sort by nearest first
    final sorted = [...users]..sort((a, b) => a.distance.compareTo(b.distance));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12), // match spacing
      itemBuilder: (context, index) {
        final u = sorted[index];
        return NearbyUserCard(
          user: u,
          onTap: onTap != null ? () => onTap!(u) : null,
        );
      },
    );
  }
}

class NearbyUserCard extends StatelessWidget {
  final NearbyUser user;
  final VoidCallback? onTap;

  const NearbyUserCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar (same treatment as PreviousMatchCard)
              Material(
                elevation: 1,
                shape: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: TColors.accent.withAlpha(255),
                    child: Text(
                      _initials(user.username),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + distance (distance on the right like date)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatDistanceString(user.distance),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final last  = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
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

