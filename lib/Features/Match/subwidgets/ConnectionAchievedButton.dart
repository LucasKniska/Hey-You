import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hey_you/Features/Match/controllers/meetNow_controller.dart';

import '../../../Data/models/CurrentMatch.dart';
import '../../../utils/constants/connection_parameters.dart';
import '../../../utils/constants/sizes.dart';

class ConnectionAchieved extends StatelessWidget {
  CurrentMatch current;
  MeetNowController pageController;
  int distance;

  ConnectionAchieved({
    super.key,
    required this.current,
    required this.pageController,
    required this.distance,
  });

  Widget basicButton() {
    return Column(
      children: [
        SizedBox(height: TSizes.spaceBtwItems),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              pageController.confirmMeeting();
            },
            child: const Text('Connection Achieved?'),
          ),
        ),
      ],
    );
  }

  Widget waitingOnUserButton() {
    return Column(
      children: [
        SizedBox(height: 4),

        Center(
          child: Text(
            'The other user has completed the match!',
            style: TextStyle(color: Colors.grey),
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              pageController.confirmMeeting();
            },
            child: const Text('Connection Achieved?'),
          ),
        ),
      ],
    );
  }

  Widget waitingOnOtherButton() {
    return Column(
      children: [
        SizedBox(height: 4),

        Center(
          child: Text(
            'Waiting on other user to complete the match!',
            style: TextStyle(color: Colors.grey),
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 20),

                // X icon on the left
                SizedBox(
                  width: 20,
                  height: 20,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(), // Removes default min size
                    onPressed: pageController.cancelConfirmMeeting,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16, // Optional: reduce size to better fit inside 20x20
                    ),
                  ),
                ),


                // Centered text
                Expanded(
                  child: Center(
                    child: Text(
                      'Connection Achieved?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // Circular progress indicator on the right
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),

                SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (distance < TConnectionParameters.distanceToConnection) {
      int other =
          current.userData[0].id == FirebaseAuth.instance.currentUser!.uid
              ? 1
              : 0;

      // Return waiting on other user to check completed
      if (pageController.pressedConnectionAchieved &&
          current.userData[other].response != 'completed') {
        return waitingOnOtherButton();
      }
      // return waiting on you to check completed
      else if (current.userData[other].response == 'completed' &&
          !pageController.pressedConnectionAchieved) {
        return waitingOnUserButton();
      }
      // No one has pressed anything yet
      else {
        return basicButton();
      }
    } else {
      return SizedBox.shrink();
    }
  }
}
