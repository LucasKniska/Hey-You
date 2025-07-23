import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:hey_you/Data/repositories/matching/match_repository.dart';
import 'package:hey_you/Features/Match/controllers/howToMeet_controller.dart';
import '../../../Data/models/CurrentMatch.dart';
import '../../../utils/constants/colors.dart';

class MeetNowLater extends StatefulWidget {
  const MeetNowLater({super.key, required this.user});

  final int user;

  @override
  State<MeetNowLater> createState() => _MeetNowLaterState();
}

class _MeetNowLaterState extends State<MeetNowLater> {

  final matchRepo = MatchRepository.instance;

  String noDecisionSubtext() {
    if (widget.user == 1) {
      if (matchRepo.currentMatch!.userData[0].response != 'not_selected') {
        return 'The other user wants to connect!';
      } else {
        return 'Want to Connect? Spark the Connection!';
      }
    } else {
      if (matchRepo.currentMatch!.userData[1].response != 'not_selected') {
        return 'The other user wants to connect!';
      } else {
        return 'Want to Connect? Spark the Connection!';
      }
    }
  }

  Widget noDecision(CurrentMatch current) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Center(
          child: Text(
            noDecisionSubtext(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
            ),
            onPressed: () => {HowToMeetController.meetNowControl(current), setState((){})},
            child: Text(
              'Meet Now',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget meetNow(CurrentMatch current) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Attempting to connect with other user!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                onPressed: null, // Disabled while loading
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Text(
                    'Attempting to connect now',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // X icon button (left)
              Positioned(
                left: 10,
                child: IconButton(
                  onPressed: () =>
                      {HowToMeetController.noDecisionControl(current), setState((){})},
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  splashRadius: 20,
                  tooltip: 'Cancel',
                ),
              ),
              // Spinner (right)
              const Positioned(
                right: 18,
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {

      // Always get the latest value INSIDE the Obx!
      final match = MatchRepository.instance.currentMatchRx.value;
      print(match);

      if (match == null) {
        return const SizedBox.shrink();
      }
      // Defensive: userData list check (avoid range error)
      if (widget.user >= match.userData.length) {
        return const Text("Invalid user index");
      }
      final response = match.userData[widget.user].response;


      // You can use a switch or if/else here
      switch (response) {
        case 'not_selected':
          return noDecision(match);
        case 'meet_now':
          return meetNow(match);
        default:
          return noDecision(match);
      }
    });
  }

}
