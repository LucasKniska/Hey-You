

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hey_you/Features/ViewConnections/previousConnections.dart';
import 'package:http/http.dart' as http;

import '../../../Common/navigation_menu.dart';
import '../../../Data/repositories/user/user_repository.dart';
import '../../../utils/constants/api_constants.dart';
import '../../ViewConnections/controllers/previousConnections_controller.dart';

class MeetNowController {

  bool connected = false;
  bool pressedConnectionAchieved = false;
  final currentUser = UserRepository.instance.currentUser;

  Future<void> confirmMeeting (String address) async {

    pressedConnectionAchieved = true;
    String c = currentUser.currentMatch;

    final url = Uri.parse(APIConstants.completeMatch);

    await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'match_id': c,
          'user_id': FirebaseAuth.instance.currentUser!.uid,
          'address': address.toString()
        })
    );

    print('Meet Now Controller: 38 updating contacts');
    PreviousConnectionController.instance.fetchPreviousMatches(UserRepository.instance.currentUser);
  }

  Future<void> cancelConfirmMeeting() async {

    pressedConnectionAchieved = false;
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