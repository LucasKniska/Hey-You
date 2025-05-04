
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../Data/repositories/connections/CurrentMatch.dart';
import '../../../Data/repositories/user/user_repository.dart';
import '../../../utils/constants/colors.dart';

class MeetNowLater extends StatefulWidget {
  const MeetNowLater({super.key});

  @override
  State<MeetNowLater> createState() => _MeetNowLaterState();
}

class _MeetNowLaterState extends State<MeetNowLater> {

  late CurrentMatch current;
  // The user is whichever index this current user is within the current match
  late int user;

  Future<CurrentMatch?> loadCurrentMatch(String matchId) async {
    final doc = await FirebaseFirestore.instance
        .collection('Matches')
        .doc(matchId)
        .get();

    if (doc.exists) {
      CurrentMatch current = CurrentMatch.fromJson(doc.data()!);

      return current;
    }

    return null;
  }


  @override
  Widget build(BuildContext context) {

    // Update the current match variable whenever it updates on firebase
    FirebaseFirestore.instance.collection('Users').doc(currentUser.id).snapshots().listen((snapshot) async {

      final match = snapshot.data()?['CurrentMatch'];
      if (match != null && match != '') {
        CurrentMatch? currentMatch = await loadCurrentMatch(match);

        if (currentMatch == null) return;

        int user = 0;

        if (currentMatch.userData[user].id == currentUser.id) {
          user = 1;
        }

        if(current != currentMatch){
          setState(() {
            current = currentMatch;
          });
        }
      }

    });


    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.secondary,
            ),
            onPressed: () => Navigator.pop(context, 'meet_now'),
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
            onPressed: () => Navigator.pop(context, 'meet_later'),
            child: Text(
              'Meet Later',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
