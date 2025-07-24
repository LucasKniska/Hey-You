
import 'package:hey_you/Data/repositories/matching/match_repository.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';

import '../../../Data/models/CurrentMatch.dart';


class HowToMeetController {
  static void meetNowControl(CurrentMatch c) {

    print('Meeting now');

    final currentUser = UserRepository.instance.currentUser;

    if(currentUser.id == c.userData[0].id){
      c.userData[0].response = 'meet_now';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    } else {
      c.userData[1].response = 'meet_now';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    }

  }

  static void noDecisionControl(CurrentMatch c){

    print('no decision');


    final currentUser = UserRepository.instance.currentUser;

    if(currentUser.id == c.userData[0].id){
      c.userData[0].response = 'not_selected';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    } else {
      c.userData[1].response = 'not_selected';
      MatchRepository.instance.saveCurrentMatchRecord(c);
    }

  }

}