import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Data/models/CurrentMatch.dart';
import 'package:hey_you/Features/Match/ConnectedSplashScreen/ConnectedSplashScreen.dart';
import 'package:hey_you/Features/Match/RejectedSplashScreen/RejectedSplashScreen.dart';
import 'package:hey_you/Features/Match/controllers/howToMeet_controller.dart';
import 'package:hey_you/Features/Match/subwidgets/MeetNowLater.dart';

import '../../Data/models/QuizQuestions.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/sizes.dart';
import 'RejectedSplashScreen/AnimatedXMark.dart';

class MatchPopup extends StatefulWidget {
  final CurrentMatch current;

  const MatchPopup({super.key, required this.current});

  @override
  State<MatchPopup> createState() => _MatchPopupState();
}

class _MatchPopupState extends State<MatchPopup> {
  late Timer _timer;
  late Duration _remaining;


  late CurrentMatch current;
  // The user is whichever index this current user is within the current match
  late int user;
  late UserData other;

  @override
  void initState() {
    super.initState();
    _remaining = widget.current.expirationTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {

      if(context.mounted) {
        final Duration newRemaining = widget.current.expirationTime.difference(
          DateTime.now(),
        );

        setState(() => _remaining = newRemaining);
      }
    });

    user = 1;
    other = widget.current.userData[0];
    if(widget.current.userData[0].id == currentUser.id){
      user = 0;
      other = widget.current.userData[1];
    }

    current = widget.current;

  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }




  @override
  Widget build(BuildContext context) {

    // Update the current match variable whenever it updates on firebase
    FirebaseFirestore.instance.collection('Users').doc(currentUser.id)
        .snapshots()
        .listen((snapshot) async {
      final match = snapshot.data()?['CurrentMatch'];
      if (match != null && match != '') {
        CurrentMatch? currentMatch = await HowToMeetController.loadCurrentMatch(match);

        if (currentMatch == null) return;

        try {
          if (current != currentMatch) {
            setState(() {

              print("UPDATED OTHER");

              current = currentMatch;

              // u variable is set to whichever the current user is not
              int u = 0;
              if (current.userData[u].id == currentUser.id) {
                u = 1;
              }
              other = current.userData[u];

            });
          }
        } catch (e) {
          setState(() {
            current = currentMatch;

            // u variable is set to whichever the current user is not
            int u = 0;
            if (current.userData[u].id == currentUser.id) {
              u = 1;
            }
            other = current.userData[u];

          });
        }
      }
    });


    // Checks if the match has been confirmed
    if( (other.response == 'meet_now' || other.response == 'meet_later') && (current.userData[user].response == 'meet_now' || current.userData[user].response == 'meet_later')){

      // Change the data to create a new match
      HowToMeetController.updateMatchStatus(current);

      // Loading screen type
      return ConnectedSplashScreen(
          onFinish: () => {
            Navigator.pop(context)
          }
      );

    }

    // Checks if the timer has run out
    if(_remaining < Duration.zero){
      print("DELETING CURRENT MATCH");

      HowToMeetController.deleteCurrentMatch(current);


    // Loading screen type
      return RejectedSplashScreen(
        onFinish: () => {
          // Change the data to create a new match
          Navigator.pop(context)
        },
      );
    }


    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: TSpacingStyle.normalPadding / 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Hey You',
              //       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              //     ),
              //     IconButton(
              //       icon: const Icon(Icons.close),
              //       onPressed: () => Navigator.pop(context, 'reject'),
              //     )
              //   ],
              // ),
              const SizedBox(height: TSizes.spaceBtwItems),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    other.userName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'XX Connections',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),

              const Divider(thickness: 1.5),

              Row(
                children: [
                  Text(
                    'Time to make connection: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    _formatDuration(_remaining),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  other.userBio.isEmpty ? 'No User Bio' : other.userBio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              Text(
                'Similar Interests and Traits:',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: TSizes.spaceBtwItems / 2),

              ...current.related.map(
                    (t) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    questionList[int.parse(t)].title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              const SizedBox(height: TSizes.spaceBtwItems / 2),

              MeetNowLater(current: current, user: user)

            ],
          ),
        ),
      );

  }
}
