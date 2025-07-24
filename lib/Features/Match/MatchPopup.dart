import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Data/models/CurrentMatch.dart';
import 'package:hey_you/Data/repositories/matching/match_repository.dart';
import 'package:hey_you/Features/Match/controllers/howToMeet_controller.dart';
import 'package:hey_you/Features/Match/subwidgets/MeetNowLater.dart';

import '../../Data/models/QuizQuestions.dart';
import '../../Data/models/UserModel.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import 'MatchesPage.dart';
import 'SplashScreens/ConnectedSplashScreen/ConnectedSplashScreen.dart';
import 'SplashScreens/RejectedSplashScreen/RejectedSplashScreen.dart';

class MatchPopup extends StatefulWidget {
  const MatchPopup({super.key});

  @override
  State<MatchPopup> createState() => _MatchPopupState();
}

class _MatchPopupState extends State<MatchPopup> {
  MatchRepository matchRepo = MatchRepository.instance;

  late int user;
  late UserData other;

  final double kmToMilesFactor = 0.621371;

  @override
  void initState() {
    final UserModel currentUser = UserRepository.instance.currentUser;
    CurrentMatch current = MatchRepository.instance.currentMatch!;

    user = 1;
    other = current.userData[0];
    if (current.userData[0].id == currentUser.id) {
      user = 0;
      other = current.userData[1];
    }

    current = current;

    super.initState();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  Widget distanceText() {
    return Obx(() {
      if (matchRepo.currentMatchRx.value == null) return Text('');

      return Text(
        '${(matchRepo.currentMatchRx.value!.distance * kmToMilesFactor).toStringAsFixed(2)} miles',
        style: Theme.of(context).textTheme.bodySmall,
      );
    });
  }

  Widget relatedInfo() {
    return Obx(() {
      if (matchRepo.currentMatchRx.value == null) return Text('');

      return Column(
        children:
            matchRepo.currentMatchRx.value!.related
                .map(
                  (t) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[100]!),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.07),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue[300],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            t,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black,
      elevation: 10,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              32,
              20,
              20,
            ), // More top space
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(blurRadius: 6, color: Colors.black12),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: TColors.primary.withAlpha(180),
                        child: Text(
                          other.userName[0] +
                              other.userName[other.userName.length - 2],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            other.userName,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${other.connections} Connection${other.connections == 1 ? '' : 's'}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.place,
                                size: 16,
                                color: Colors.blue[200],
                              ),
                              SizedBox(width: 4),

                              distanceText(),

                              SizedBox(width: 12),
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: Colors.blue[200],
                              ),

                              SizedBox(width: 4),

                              Obx(
                                () => Text(
                                  _formatDuration(
                                    MatchRepository
                                        .instance
                                        .remainingTimeRx
                                        .value,
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        (MatchRepository
                                                    .instance
                                                    .remainingTimeRx
                                                    .value
                                                    .inSeconds <
                                                120)
                                            ? Colors.red
                                            : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(thickness: 1.5),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Biography: ',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              other.userBio.isEmpty
                                  ? 'No User Bio'
                                  : other.userBio,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                other.userBio.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                            fontStyle:
                                other.userBio.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Why matched chips
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Why we matched you:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                relatedInfo(),

                const SizedBox(height: 18),

                // Meet Now button
                MeetNowLater(user: user),

                const SizedBox(height: 2),
              ],
            ),
          ),
          // X button
          Positioned(
            right: 2,
            top: 2,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.grey[400], size: 26),
              onPressed: () => Navigator.pop(context, 'reject'),
              tooltip: "Close",
            ),
          ),
        ],
      ),
    );
  }
}
