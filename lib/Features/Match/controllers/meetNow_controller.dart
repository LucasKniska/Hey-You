

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../Data/repositories/connections/match_repository.dart';
import '../../../Data/repositories/user/user_repository.dart';
import '../../../utils/constants/api_constants.dart';

class MeetNowController {

  bool connected = false;


  Future<void> confirmMeeting () async {

    Get.put(MatchRepository());

    String c = currentUser.currentMatch;

    final url = Uri.parse(APIConstants.completeMatch);

    print(url);
    final http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': c,
          'user_id': currentUser.id
        })
    );

    // Decode JSON body
    final Map<String, dynamic> data = json.decode(response.body);
    final String status = data['status'];

    print(status);

    if (status == 'Match closed') {
      connected = true;
    }
  }

}