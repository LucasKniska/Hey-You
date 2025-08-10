import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:hey_you/Common/widgets/emptyFieldWidget.dart';
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

      setState(() {
        previousMatches = matches;
        loading = false;
      });
    } catch (e) {
      print("Error fetching previous matches: $e");

      setState(() {
        loading = false;
        error = true;
      });
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
            itemCount: previousMatches.length,
            itemBuilder: (context, index) {
              return _ConnectionRow(match: previousMatches[index]);
            },
          )
        else if (!error)
          EmptyStateWidget(
            title: 'You currently have no matching',
            description: 'Match with someone to fill out your list of contacts!',
          )
        else
            EmptyStateWidget(
              title: 'We are having errors finding your previous connections',
              description: 'Reload app to try again',
            )
      ],
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  final PreviousMatch match;

  const _ConnectionRow({required this.match});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        connectionTitle(match.previousConnectionDateDetails(), context),
        previousCard(match.previousConnectionUserDetails(), context),
        SizedBox(height: TSizes.spaceBtwItems)
      ]
    );
  }


  Widget connectionTitle(String text, BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
    );
  }

  Widget previousCard(String text, BuildContext context) {
    return Card(
      color: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          text,
            style: Theme.of(context).textTheme.bodyMedium
        ),
        trailing: Icon(Icons.arrow_drop_down, color: Colors.white),
      ),
    );
  }
}
