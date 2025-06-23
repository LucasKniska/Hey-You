import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Data/models/CurrentMatch.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/Features/Match/MeetNowPage.dart';
import 'package:hey_you/Features/Match/scheduledMeetUps.dart';
import 'package:hey_you/utils/constants/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_string.dart';
import 'BottomSheet.dart';
import 'MatchCompleteSpashScreen/ConnectedLineSplashScreen.dart';
import 'MatchPopup.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Timer? matchTimer;
  CurrentMatch? current;
  int? user;

  RxString MatchHeader = ''.obs;

  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _userMatchSubscription;

  @override
  void initState() {
    super.initState();

    _userMatchSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.id)
        .snapshots()
        .listen((snapshot) async {

      if (!snapshot.exists || !mounted) return;

      final currentMatchId = snapshot.data()?['CurrentMatch'];

      if (currentMatchId == null || currentMatchId == '') {
        setState(() {
          current = null;
        });

        return;
      };

      CurrentMatch? currentMatchNow = await loadCurrentMatch(currentMatchId);

      if (!mounted || currentMatchNow == null || currentMatchNow == current) return;

      var matchHeaderUpdate;
      if (currentMatchNow.status == 'new') {
        matchHeaderUpdate = 'New Connection!'.obs;
      } else if (currentMatchNow.status == 'now') {
        matchHeaderUpdate = 'Meet Up Now!'.obs;
      } else {
        matchHeaderUpdate = ''.obs;
      }

      setState(() {
        current = currentMatchNow;
        user = (currentMatchNow.userData[0].id == currentUser.id) ? 0 : 1;
        MatchHeader = matchHeaderUpdate;
      });

      if (currentMatchNow.status != 'new') return;

      final expiration = currentMatchNow.expirationTime;
      final Rx<Duration> countdown = expiration.difference(DateTime.now()).obs;

      matchTimer?.cancel();
      matchTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        final newRemaining = expiration.difference(DateTime.now());
        countdown.value = newRemaining;
        if (newRemaining <= Duration.zero) {
          t.cancel();
          matchTimer = null;
        }
      });

      final int userNum = currentMatchNow.userData[0].id == currentUser.id ? 1 : 0;

      Get.snackbar(
        'New Match!',
        'You matched with ${currentMatchNow.userData[userNum].userName} Tap to view.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        onTap: (snack) async {
          try {
            if (currentMatchNow.id.isNotEmpty) {
              await Get.dialog(MatchPopup(current: currentMatchNow));

              final refreshed = await loadCurrentMatch(currentMatchNow.id);


              if (refreshed != null && user != null && refreshed.status == 'new') {
                MatchHeader = 'New Connection!'.obs;
              } else if (refreshed != null && user != null && refreshed.status == 'now') {
                MatchHeader = 'Meet Up Now!'.obs;
              }

              if (refreshed != null) {
                setState(() {
                  current = refreshed;
                });
              }

            }
          } catch (e) {}
        },
      );
    });
  }

  @override
  void dispose() {
    _userMatchSubscription.cancel();
    matchTimer?.cancel();
    super.dispose();
  }

  Future<CurrentMatch?> loadCurrentMatch(String matchId) async {
    final doc = await FirebaseFirestore.instance.collection('Matches').doc(matchId).get();
    if (doc.exists) {
      return CurrentMatch.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> _openModificationSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const ModificationBottomSheet(),
        );
      },
    );
    Get.put(UserRepository());
    UserRepository.instance.saveUserRecord(currentUser);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        padding: TSpacingStyle.normalPadding,
        child: Column(
          children: [


            if (current != null) ...[
              Obx(() => Text(
                MatchHeader.value,
                style: Theme.of(context).textTheme.headlineMedium,
              )),
              const SizedBox(height: 8),
              Material(
                color: TColors.accent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    if (current!.id.isNotEmpty && current!.status == 'new') {
                      Get.dialog(MatchPopup(current: current!));
                    } else {
                      Get.to(() => MeetNowPage(
                        current: current!,
                        userLocation: current!.userData[0].location,
                        otherUserLocation: current!.userData[1].location,
                      ));
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  highlightColor: Colors.white.withOpacity(0.2),
                  splashColor: Colors.black.withOpacity(0.1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        (user! == 1) ? current!.userData[0].userName : current!.userData[1].userName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(thickness: 1, color: Colors.black12),
            ],
            /// Scheduled Meet Ups Section
            sectionTitle(Iconsax.clock, TTexts.scheduledMeetUps),
            SizedBox(height: TSizes.spaceBtwItems),

            ScheduledConnections(),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openModificationSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}


Widget sectionTitle(IconData icon, String title) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: TColors.accent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        SizedBox(width: 10),
        Icon(icon, color: Colors.black),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
