
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/navigation_menu.dart';
import 'package:hey_you/Features/Match/SplashScreens/RejectedSplashScreen/RejectedSplashScreen.dart';
import 'package:http/http.dart' as http;

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

        } catch (e) {
          _currentMatch.value = null;
          _matchTimer?.cancel();
          print('Error updating current match: $e');
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
      _actionsHandler();
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

  Future<void> saveCurrentMatchRecord(CurrentMatch current) async {
    try{
      await _db.collection('Matches').doc(current.id).set(current.toJson());
    } catch (e) {
      throw 'Something went wrong saving current match.';
    }
  }

  void stopListeningToMatches() {
    _currentMatchListener?.cancel();
  }

  void _actionsHandler(){

    print('Remaining time: ${_remainingTime.value.inSeconds}');

    /// Ready to meet
    if (currentMatch!.userData[0].response == 'meet_now' && currentMatch!.userData[1].response == 'meet_now') {
      _matchTimer?.cancel();
      acceptMatch();
    }

    /// Delete the possible connection
    if(_remainingTime.value.inSeconds == 0){

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

    final url = Uri.parse(APIConstants.updateMatchStatus);

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