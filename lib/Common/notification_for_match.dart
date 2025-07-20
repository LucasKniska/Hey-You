

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Data/models/CurrentMatch.dart';
import '../Data/models/UserModel.dart';
import '../Data/repositories/user/user_repository.dart';
import '../Features/Match/MatchPopup.dart';

Future<CurrentMatch?> setupNotification() async {

  CurrentMatch? matchFound;
  final userRepo = UserRepository.instance;

  // Shows the popup if necessary
  ever<UserModel?>(userRepo.currentUserRx, (user) async {
    String currentMatch = user!.currentMatch;

    if (currentMatch.isNotEmpty) {

      // The item in current match that is showing up
      CurrentMatch? currentMatchNow = await loadCurrentMatch(currentMatch);

      if (currentMatchNow == null) return;

      matchFound = CurrentMatch.fromSame(currentMatchNow);
      print(matchFound);

      if (currentMatchNow.status != 'new') return;

      int userNum = 0;

      if (currentMatchNow.userData[userNum].id == user.id) {
        userNum = 1;
      }


      Get.snackbar(
        'New Match!',
        'You matched with ${currentMatchNow.userData[userNum].userName} Tap to view.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        isDismissible: true,
        onTap: (snack) {
          try {
            if (currentMatchNow.id != '') {
              Get.dialog(MatchPopup(current: currentMatchNow, ));
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