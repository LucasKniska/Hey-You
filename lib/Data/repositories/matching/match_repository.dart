
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/navigation_menu.dart';
import 'package:hey_you/Features/Match/SplashScreens/RejectedSplashScreen/RejectedSplashScreen.dart';
import 'package:http/http.dart' as http;

import '../../../Features/Match/MatchPopup.dart';
import '../../../Features/Match/SplashScreens/ConnectedSplashScreen/ConnectedSplashScreen.dart';
import '../../../utils/constants/api_constants.dart';
import '../../models/CurrentMatch.dart';
import '../user/user_repository.dart';

class MatchRepository extends GetxController {
  static MatchRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _currentMatchListener; // Listener for the active match
  final Rx<CurrentMatch?> _currentMatch = Rx<CurrentMatch?>(null); // Reactive current match

  CurrentMatch? get currentMatch => _currentMatch.value;
  Rx<CurrentMatch?> get currentMatchRx => _currentMatch;

  final Rx<Duration> _remainingTime = Duration.zero.obs;
  Timer? _matchTimer;

  Duration get remainingTime => _remainingTime.value;
  Rx<Duration> get remainingTimeRx => _remainingTime;

  bool beenToMeetNowPage = false;
  bool newMatchSeen = false;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _currentMatchListener?.cancel();
    _matchTimer?.cancel();
    super.onClose();
  }

  void startCurrentMatchListener() {
    final String matchId = UserRepository.instance.currentUser.currentMatch;

    print('Current match Id $matchId');
    if (matchId.isEmpty) {
      _matchTimer?.cancel();
      _currentMatchListener?.cancel();
      _currentMatch.value = null;
      return;
    }

    _currentMatchListener?.cancel();

    _currentMatchListener = _db
        .collection('Matches')
        .doc(matchId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {

          final parsed = CurrentMatch.fromJson(snapshot.data() as Map<String, dynamic>);
          _currentMatch.value = parsed;
          _startMatchTimer(parsed);


          if(newMatchSeen && currentMatch != null && currentMatch!.status == 'new') {

            int userNum = 0;
            if (currentMatch!.userData[userNum].id == FirebaseAuth.instance.currentUser!.uid) {
              userNum = 1;
            }

            if(!Get.isSnackbarOpen){
              Get.snackbar(
                'New Match!',
                'You matched with ${currentMatch!.userData[userNum].userName} Tap to view.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                duration: const Duration(seconds: 8),
                isDismissible: true,
                onTap: (snack) {
                  Get.closeCurrentSnackbar();
                  Get.dialog(MatchPopup());
                },
              );
            }
            newMatchSeen = false;
          }

        } catch (e, stackTrace) {
          _currentMatch.value = null;
          _matchTimer?.cancel();
          print('Error updating current match: $e');
          print(stackTrace);
        }
      }
    });
  }

  void _startMatchTimer(CurrentMatch parsed) {
    // Stop any previous timer
    _matchTimer?.cancel();

    // Calculate initial remaining time
    _updateRemainingTime(parsed);

    // Start the periodic timer
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime(parsed);
      _creatingMatchActionsHandler();
    });
  }

  void _updateRemainingTime(CurrentMatch parsed) {
    final match = parsed;

    final Duration diff = match.expirationTime.difference(DateTime.now());
    if (diff.isNegative) {
      _remainingTime.value = Duration.zero;
      _matchTimer?.cancel();
      return;
    }
    _remainingTime.value = diff;
  }

  void stopListeningToMatches() {
    _currentMatchListener?.cancel();
  }

  void _creatingMatchActionsHandler(){

    print('Remaining time: ${_remainingTime.value.inSeconds}');

    /// Ready to meet
    if (currentMatch!.userData[0].response == 'meet_now' && currentMatch!.userData[1].response == 'meet_now' && currentMatch!.status != 'now') {
      _matchTimer?.cancel();
      acceptMatch();

      Get.to(() => ConnectedSplashScreen(onFinish: () {
        print('completed connection screen');
        currentMatch!.status = 'now';
        Get.back();
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      }));
    }

    /// Delete the possible connection
    if(_remainingTime.value.inSeconds == 0 && currentMatch!.status != 'now'){

      //TODO Add check for if it is looking at the correct expiration time

      if (currentMatch!.userData[0].response != 'meet_now' || currentMatch!.userData[1].response != 'meet_now') {
        _matchTimer?.cancel();
        deleteCurrentMatch();
        Get.to(() => RejectedSplashScreen(onFinish: () {
          print('completed rejection screen');
          Get.back();
          if (Get.isDialogOpen == true) {
            Get.back();
          }
          _currentMatch.value = null;

        }));
      }
    }
  }

  Future<void> updateCurrentMatchDecision(String decision) async {

    final url = Uri.parse(APIConstants.updateUserMatchData);

    final currentMatchId = MatchRepository.instance.currentMatch!.id;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'matchId': currentMatchId,
          'userId': currentUserId,
          'decision': decision
        })
    );
  }

  Future<void> deleteCurrentMatch() async {
    final url = Uri.parse(APIConstants.deleteMatch);

    await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': currentMatch!.id
        })
    );
  }

  Future<void> acceptMatch() async {

    final url = Uri.parse(APIConstants.acceptMatch);

    await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': currentMatch!.id
        })
    );
  }
}