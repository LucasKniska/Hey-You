import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/connections/match_repository.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';

import '../../../Data/models/CurrentMatch.dart';


class HowToMeetController extends GetxController{
  static HowToMeetController get instance => Get.find();

  static void meetNowControl(CurrentMatch c) {

    Get.put(MatchRepository());

    if(currentUser.id == c.userData[0].id){
      c.userData[0].response = 'meet_now';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    } else {
      c.userData[1].response = 'meet_now';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    }

  }

  static void meetLaterControl(CurrentMatch c){

    Get.put(MatchRepository());

    if(currentUser.id == c.userData[0].id){
      c.userData[0].response = 'meet_later';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    } else {
      c.userData[1].response = 'meet_later';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    }
  }

  static void noDecisionControl(CurrentMatch c){
    Get.put(MatchRepository());

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

  static void deleteCurrentMatch(CurrentMatch c){
    print("Would delete current match");
  }

  // Call api to create a new match?
  static void createNewMatch(CurrentMatch c){
    print("Would create a new match with API");
  }

}