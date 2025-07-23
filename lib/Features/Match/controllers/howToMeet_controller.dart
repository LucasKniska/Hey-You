import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/matching/match_repository.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/utils/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import '../../../Data/models/CurrentMatch.dart';


class HowToMeetController extends GetxController{
  static HowToMeetController get instance => Get.find();
  static final userRepo = UserRepository.instance;

  static void meetNowControl(CurrentMatch c) {
    final currentUser = userRepo.currentUser;

    if(currentUser.id == c.userData[0].id){
      c.userData[0].response = 'meet_now';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    } else {
      c.userData[1].response = 'meet_now';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    }

  }

  static void meetLaterControl(CurrentMatch c){

    final currentUser = userRepo.currentUser;

    if(currentUser.id == c.userData[0].id){
      c.userData[0].response = 'meet_later';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    } else {
      c.userData[1].response = 'meet_later';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    }
  }

  static void noDecisionControl(CurrentMatch c){
    final currentUser = userRepo.currentUser;

    if(currentUser.id == c.userData[0].id){
      c.userData[0].response = 'not_selected';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    } else {
      c.userData[1].response = 'not_selected';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    }

  }

  static Future<CurrentMatch?> loadCurrentMatch(String matchId) async {
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

  static Future<void> deleteCurrentMatch(CurrentMatch c) async {

    final url = Uri.parse(APIConstants.deleteMatch);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': c.id
      })
    );
  }

  // Call api to create a new match?
  static Future<void> updateMatchStatus(CurrentMatch c) async {
    final url = Uri.parse(APIConstants.updateMatchStatus);

    final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': c.id
        })
    );

    print(response);
  }

}