// allPreviousConnections.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Data/models/PreviousMatch.dart';
import '../../utils/constants/colors.dart';

class AllPreviousConnectionsPage extends StatelessWidget {
  final List<PreviousMatch> matches;
  final void Function(PreviousMatch)? onTap;

  const AllPreviousConnectionsPage({
    super.key,
    required this.matches,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Copy and sort (most recent first)
    final sorted = [...matches]..sort((a, b) => b.createdOn.compareTo(a.createdOn));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Previous Connections'),
      ),
      body: sorted.isEmpty
          ? const _EmptyAllState()
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => PreviousMatchCard(
          match: sorted[i],
          onTap: onTap,
        ),
      ),
    );
  }
}

class PreviousMatchCard extends StatelessWidget {
  final PreviousMatch match;
  final void Function(PreviousMatch)? onTap;

  const PreviousMatchCard({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentId = FirebaseAuth.instance.currentUser?.uid;
    final other = match.userData.firstWhere(
          (u) => u.id != currentId,
      orElse: () => match.userData.first,
    );

    final initials = _initials(other.userName);
    final dateStr = DateFormat('MM/dd/yyyy').format(match.createdOn);
    final where = match.meetingPlace['location'] ??
        (match.meetingPlace['formatted'] ??
            (match.possiblePlaces.isNotEmpty ? match.possiblePlaces.first : 'Unknown place'));
    final why = match.related.isNotEmpty ? match.related.first : 'Matched';

    final radius = BorderRadius.circular(18);

    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => onTap?.call(match),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Material(
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
                      initials,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            other.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      where,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      why,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _EmptyAllState extends StatelessWidget {
  const _EmptyAllState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.handshake_outlined, size: 52),
            const SizedBox(height: 12),
            Text(
              'No previous connections yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Once you match and meet, they’ll show up here with the place and reason.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
