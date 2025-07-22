import 'package:flutter/material.dart';
import 'package:hey_you/Features/Match/controllers/howToMeet_controller.dart';
import '../../../Data/models/CurrentMatch.dart';
import '../../../utils/constants/colors.dart';

class MeetNowLater extends StatefulWidget {
  const MeetNowLater({super.key, required this.current, required this.user});

  final CurrentMatch current;
  final int user;

  @override
  State<MeetNowLater> createState() => _MeetNowLaterState();
}

class _MeetNowLaterState extends State<MeetNowLater> {

  String noDecisionSubtext() {
    if (widget.user == 1) {
      if (widget.current.userData[0].response != 'not_selected') {
        return 'The other user wants to connect!';
      } else {
        return 'Want to Connect? Spark the Connection!';
      }
    } else {
      if (widget.current.userData[1].response != 'not_selected') {
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
            onPressed: () => HowToMeetController.meetNowControl(current),
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
                      HowToMeetController.noDecisionControl(current),
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
    return switch (widget.current.userData[widget.user].response) {
      'not_selected' => noDecision(widget.current),
      'meet_now' => meetNow(widget.current),
      String() => noDecision(widget.current),
    };
  }
}
