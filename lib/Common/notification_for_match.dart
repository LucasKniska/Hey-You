

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Data/models/CurrentMatch.dart';
import '../Data/repositories/user/user_repository.dart';
import '../Features/Match/MatchPopup.dart';

Future<CurrentMatch?> setupNotification() async {

  final currentUser = UserRepository.instance.currentUser;
  CurrentMatch? matchFound;

  // Shows the popup if necessary
  FirebaseFirestore.instance
      .collection('Users')
      .doc(currentUser.id)
      .snapshots()
      .listen((snapshot) async {
    final currentMatch = snapshot.data()?['CurrentMatch'];
    if (currentMatch != null && currentMatch != '') {
      // The item in current match that is showing up
      CurrentMatch? currentMatchNow = await loadCurrentMatch(currentMatch);

      if (currentMatchNow == null) return;

      matchFound = CurrentMatch.fromSame(currentMatchNow);
      print(matchFound);

      if (currentMatchNow.status != 'new') return;

      int userNum = 0;

      if (currentMatchNow.userData[userNum].id == currentUser.id) {
        userNum = 1;
      }

      final expiration = currentMatchNow.expirationTime;
      final Rx<Duration> countdown =
          expiration.difference(DateTime.now()).obs;

      var matchTimer;

      matchTimer?.cancel(); // Cancel any existing timer
      matchTimer = Timer.periodic(Duration(seconds: 1), (t) {
        final newRemaining = expiration.difference(DateTime.now());
        countdown.value = newRemaining;
        if (newRemaining <= Duration.zero) {
          t.cancel();
          matchTimer = null;
        }
      });

      Get.snackbar(
        'New Match!',
        'You matched with ${currentMatchNow.userData[userNum].userName} Tap to view.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        onTap: (snack) {
          try {
            if (currentMatchNow.id != '') {
              Get.dialog(MatchPopup(current: currentMatchNow));
            }
          } catch (e) {}
        },
      );
    }

    });

  return matchFound;
}


Future<CurrentMatch?> loadCurrentMatch(String matchId) async {
  final doc =
  await FirebaseFirestore.instance
      .collection('Matches')
      .doc(matchId)
      .get();

  if (doc.exists) {
    CurrentMatch current = CurrentMatch.fromJson(doc.data()!);

    return current;
  }

  return null;
}