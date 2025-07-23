
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/CurrentMatch.dart';
import '../../models/UserModel.dart';
import '../user/user_repository.dart';

class MatchRepository extends GetxController {
  static MatchRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel currentUser = UserRepository.instance.currentUser;

  StreamSubscription<DocumentSnapshot>? _currentMatchListener; // Listener for the active match
  final Rx<CurrentMatch?> _currentMatch = Rx<CurrentMatch?>(null); // Reactive current match

  CurrentMatch get currentMatch => _currentMatch.value!;
  Rx<CurrentMatch?> get currentMatchRx => _currentMatch;


  @override
  void onInit() {
    super.onInit();
    startCurrentMatchListener();
  }

  @override
  void onClose() {
    _currentMatchListener?.cancel();
    super.onClose();
  }

  void startCurrentMatchListener() {
    final String matchId = currentUser.currentMatch;

    if(matchId.isEmpty) return;

    _currentMatchListener = _db
      .collection('Matches')
      .doc(matchId)
      .snapshots()
      .listen((DocumentSnapshot snapshot) {
        if(snapshot.exists && snapshot.data() != null) {
          try {
            _currentMatch.value = CurrentMatch.fromJson(snapshot.data() as Map<String, dynamic>);
            print('Current user match updated: ${_currentMatch.value!.id}');
          } catch (e) {
            print('Error updating current match: $e');
          }
        }
      });
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