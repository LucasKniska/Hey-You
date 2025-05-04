import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Data/repositories/connections/CurrentMatch.dart';
import 'package:hey_you/Features/Match/subwidgets/MeetNowLater.dart';
import 'package:hey_you/utils/constants/colors.dart';

import '../../Data/repositories/connections/QuizQuestions.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/sizes.dart';

class MatchPopup extends StatefulWidget {
  final CurrentMatch current;

  const MatchPopup({super.key, required this.current});

  @override
  State<MatchPopup> createState() => _MatchPopupState();
}

class _MatchPopupState extends State<MatchPopup> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.current.expirationTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = widget.current.expirationTime.difference(
        DateTime.now(),
      );
      if (newRemaining <= Duration.zero) {
        // timer.cancel();
        // if (mounted) Navigator.pop(context); => TODO Do something when timer hits zero
        setState(() => _remaining = newRemaining);
      } else {
        setState(() => _remaining = newRemaining);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    if(d < Duration.zero) {
      // TODO API CALL REMOVE THE CURRENT MATCH OBJECT
    }

    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    // User variable is set to whichever the current user is not
    int user = 0;
    if (widget.current.userData[user].id == currentUser.id) {
      user = 1;
    }
    UserData other = widget.current.userData[user];

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

            ...widget.current.related.map(
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

            Center(
              child: Text(
                'Want to Connect? Spark Below!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems / 2),

            MeetNowLater()

          ],
        ),
      ),
    );
  }
}
