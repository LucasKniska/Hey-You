import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';

import '../../Data/models/LeaderboardData.dart';
import '../../utils/constants/colors.dart';
import 'components/SectionCard.dart'; // LeaderboardTab + helpers

class LeaderboardPage extends StatefulWidget {
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<LBRankings> _future;
  final String userId = UserRepository.instance.currentUser.id;
  int _segment = 0; // 0: Total, 1: Current, 2: Longest

  Future<LBRankings> _fetchRankings() async {
    return UserRepository.instance.fetchRankings();
  }

  String prettyBucketName(String raw) => raw
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  @override
  void initState() {
    super.initState();
    _future = _fetchRankings();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // keepAlive
    const brandBgTop = Color(0xFFEAF3FF);
    const brandBgBottom = Color(0xFFDDEBFF);
    final bucket = prettyBucketName(UserRepository.instance.currentUser.bucketName);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [brandBgTop, brandBgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: FutureBuilder<LBRankings>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _LoadingSkeleton();
              }
              if (snap.hasError) {
                return _ErrorCard(
                  message: 'Could not load leaderboard.\n${snap.error}',
                  onRetry: () async {
                    final f =  _fetchRankings();
                    setState(() => _future = f);
                  },
                );
              }

              final data = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [


                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      children: [
                        Text('$bucket Rankings', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text('These are the most active matchers. Connect with more people to appear on the local leaderboard!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black.withOpacity(0.55))),
                        const SizedBox(height: 12),
                        const Divider(height: 24, thickness: 1, color: Color(0xFFE9EEF5)),
                      ],
                    ),
                  ),

                  const Divider(height: 24, thickness: 0, color: Color(0xFFE9EEF5)),


                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      child: _buildTabContent(data),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: _SegmentedTabs(
                      segment: _segment,
                      onChanged: (v) => setState(() => _segment = v),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(LBRankings data) {
    switch (_segment) {
      case 0:
        return LeaderboardTab(
          key: const ValueKey('tab_total'),
          entries: data.totalConnections,
          currentUserId: userId,
          valueLabel: 'matches',
          accent: Colors.blue,
          listIncludesTop3: false, // show 4–5 under the podium
        );
      case 1:
        return LeaderboardTab(
          key: const ValueKey('tab_current'),
          entries: data.currentStreak,
          currentUserId: userId,
          valueLabel: 'days',
          accent: Colors.indigo,
          listIncludesTop3: false,
        );
      case 2:
        return LeaderboardTab(
          key: const ValueKey('tab_longest'),
          entries: data.longestStreak,
          currentUserId: userId,
          valueLabel: 'days',
          accent: Colors.deepPurple,
          listIncludesTop3: false,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// ---------------- Segmented control (white track) ----------------
class _SegmentedTabs extends StatelessWidget {
  final int segment;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({required this.segment, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final track = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white, // strong definition
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        track,
        CupertinoSlidingSegmentedControl<int>(
          groupValue: segment,
          padding: const EdgeInsets.all(4),
          backgroundColor: Colors.transparent,
          thumbColor: TColors.accent.withAlpha(255),
          children: const {
            0: _TabChip(label: 'Total Matches'),
            1: _TabChip(label: 'Current Streak'),
            2: _TabChip(label: 'Longest Streak'),
          },
          onValueChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  const _TabChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// ---------------- Loading & Error ----------------
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget shimmerBox({double h = 90}) => Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          shimmerBox(h: 42),  // segmented control
          shimmerBox(h: 190), // podium
          shimmerBox(h: 168), // list
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
