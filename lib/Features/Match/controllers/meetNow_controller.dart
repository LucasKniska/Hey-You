

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../Data/repositories/connections/match_repository.dart';
import '../../../Data/repositories/user/user_repository.dart';
import '../../../utils/constants/api_constants.dart';

class MeetNowController {

  bool connected = false;
  bool pressedConnectionAchieved = false;

  Future<void> confirmMeeting () async {

    pressedConnectionAchieved = true;

    Get.put(MatchRepository());

    String c = currentUser.currentMatch;

    final url = Uri.parse(APIConstants.completeMatch);

    final http.Response response = await http.post(
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

  Future<void> cancelConfirmMeeting() async {

    pressedConnectionAchieved = false;

    Get.put(MatchRepository());

    String c = currentUser.currentMatch;
    final url = Uri.parse(APIConstants.cancelCompleteMatch);

    final http.Response response = await http.post(
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