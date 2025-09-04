import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:hey_you/Common/widgets/emptyFieldWidget.dart';
import 'package:hey_you/Features/ViewConnections/allPreviousConnections.dart';
import 'package:hey_you/Features/ViewConnections/controllers/previousConnections_controller.dart';

import '../../Data/models/PreviousMatch.dart';
import '../../Data/models/UserModel.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/sizes.dart';

class PreviousConnection extends StatefulWidget {
  const PreviousConnection({super.key});

  @override
  State<PreviousConnection> createState() => _PreviousConnection();
}

class _PreviousConnection extends State<PreviousConnection> {

  final PreviousConnectionController controller = PreviousConnectionController();
  List<PreviousMatch> previousMatches = [];
  bool loading = true;
  bool error = false;
  final userRepo = UserRepository.instance;
  int totalConnections = UserRepository.instance.currentUser.totalConnections;

  @override
  void initState() {
    super.initState();
    fetchPreviousMatches(); // Call async function
    controller.checkCurrentStreak(userRepo.currentUser);

    // Shows the popup if necessary
    ever<UserModel?>(userRepo.currentUserRx, (user) async {
      if (user == null) return;
      controller.checkCurrentStreak(userRepo.currentUser);
      if (totalConnections != user.totalConnections || previousMatches.length != totalConnections){
        totalConnections = user.totalConnections;
        fetchPreviousMatches();
      }
    });
  }

  Future<void> fetchPreviousMatches() async {
    try {
      error = false;
      loading = true;

      final matches = await controller.getPreviousMatches();

      if(!mounted) return;

      matches.sort(
          (a, b) => b.createdOn.compareTo(a.createdOn)
      );

      setState(() {
        previousMatches = matches;
        loading = false;
      });

      print('Previous matches: $previousMatches');
    } catch (e) {
      print('Error fetching previous matches: $e');

      setState(() {
        loading = false;
        error = true;
      });

      if(!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (loading)
          const Center(
            child: CircularProgressIndicator(
              color: Colors.grey,
            ),
          )
         else if (previousMatches.isNotEmpty)
           ListView.builder(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(), // Prevents scrolling inside a Column
             itemCount: 3,
             itemBuilder: (context, index) {
               return Padding(padding: EdgeInsets.only(bottom: 5), child: PreviousMatchCard(match: previousMatches[index]));
             },
           )
        else if (!error)
          EmptyStateWidget(
            title: 'You currently have no matches',
            description: 'Match with someone to fill out your list of contacts!',
          )
        else
          EmptyStateWidget(
            title: 'We can not find your previous connection right now',
            description: 'Reload the app and try again later!',
          ),

        if (previousMatches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ViewAllPreviousConnectionsButton(
              totalCount: previousMatches.length, // or omit to hide badge
              onPressed: () {
                Get.to(() => AllPreviousConnectionsPage(matches: previousMatches));
              },
            ),
          ),


      ],
    );
  }
}

class ViewAllPreviousConnectionsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int? totalCount; // optional badge, e.g., total # of previous connections
  final String label;

  const ViewAllPreviousConnectionsButton({
    super.key,
    required this.onPressed,
    this.totalCount,
    this.label = 'View all previous connections',
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF1F3F6); // light gray like the mock
    final radius = BorderRadius.circular(16);

    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // medium padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (totalCount != null) ...[
                const SizedBox(width: 8),
                _CountBadge(count: totalCount!),
              ],
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 22, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
