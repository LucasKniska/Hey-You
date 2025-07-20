

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../Common/navigation_menu.dart';
import '../../../Data/repositories/connections/match_repository.dart';
import '../../../Data/repositories/user/user_repository.dart';
import '../../../utils/constants/api_constants.dart';

class MeetNowController {

  bool connected = false;
  bool pressedConnectionAchieved = false;
  final currentUser = UserRepository.instance.currentUser;

  Future<void> confirmMeeting () async {

    pressedConnectionAchieved = true;

    Get.put(MatchRepository());

    String c = currentUser.currentMatch;

    final url = Uri.parse(APIConstants.completeMatch);

    await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': c,
          'user_id': FirebaseAuth.instance.currentUser!.uid
        })
    );

    final controller = Get.find<NavigationController>();
    controller.triggerContactsRefresh();
  }

  Future<void> cancelConfirmMeeting() async {

    pressedConnectionAchieved = false;

    Get.put(MatchRepository());

    String c = currentUser.currentMatch;
    final url = Uri.parse(APIConstants.cancelCompleteMatch);

    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': c,
        'user_id': FirebaseAuth.instance.currentUser!.uid
      })
    );
  }

}