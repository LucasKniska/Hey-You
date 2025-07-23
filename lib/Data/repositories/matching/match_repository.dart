
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/CurrentMatch.dart';
import '../../models/UserModel.dart';
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
    startCurrentMatchListener();
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



}