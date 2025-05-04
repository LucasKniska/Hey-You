import 'package:cloud_firestore/cloud_firestore.dart';
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
    if(widget.user == 1){
      if(widget.current.userData[0].response != 'not_selected'){
        return 'The other user wants to connect!';
      } else {
        return 'Want to Connect? Spark the Connection Below!';
      }
    } else {
      if(widget.current.userData[1].response != 'not_selected'){
        return 'The other user wants to connect!';
      } else {
        return 'Want to Connect? Spark the Connection!';
      }
    }
  }


  Widget noDecision(CurrentMatch current) {
    return Column(
      children: [
        Center(
          child: Text(
            noDecisionSubtext(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.secondary,
                ),
                onPressed: () => HowToMeetController.meetNowControl(current),
                child: Text(
                  'Meet Now',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.secondary,
                ),
                onPressed: () => HowToMeetController.meetLaterControl(current),
                child: Text(
                  'Meet Later',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget meetNow(CurrentMatch current) {
    return Column(
      children: [
        Center(
          child: Text(
            'Attempting to connect with other user!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: null, // Disabled while loading
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered text
                    Center(
                      child: Text(
                        'Attempting to connect now',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),

                    // X icon on the left
                    Positioned(
                      left: 10,
                      child: IconButton(
                        onPressed: () => HowToMeetController.noDecisionControl(current),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // Spinner on the right
                    const Positioned(
                      right: 10,
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget meetLater(CurrentMatch current) {
    return Column(
      children: [
        Center(
          child: Text(
            'Attempting to connect with other user!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: null, // Disabled while loading
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered text
                    Center(
                      child: Text(
                        'Attempting to connect later',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),

                    // X icon on the left
                    Positioned(
                      left: 10,
                      child: IconButton(
                          onPressed: () => HowToMeetController.noDecisionControl(current),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                      ),
                    ),

                    // Spinner on the right
                    const Positioned(
                      right: 10,
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.current.userData[widget.user].response) {
      'not_selected' => noDecision(widget.current),
      'meet_now' => meetNow(widget.current),
      'meet_later' => meetLater(widget.current),
      String() => noDecision(widget.current),
    };

  }
}
