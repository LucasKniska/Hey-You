
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:http/http.dart' as http;

import '../../../Data/models/PreviousMatch.dart';
import '../../../Data/models/UserModel.dart';
import '../../../utils/constants/api_constants.dart';

class PreviousConnectionController {

  Future<List<PreviousMatch>> getPreviousMatches() async {

    final url = Uri.parse('${APIConstants.getPreviousConnections}?user_id=${FirebaseAuth.instance.currentUser!.uid}');

    final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // Pull the list under 'previous_connections'
      final List<dynamic> connections = jsonResponse['previous_connections'] ?? [];

      // Convert each entry into a PreviousMatch
      return connections.map((json) => PreviousMatch.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch previous matches. Status code: ${response.statusCode}");
    }
  }

  Future<void> checkCurrentStreak(UserModel user) async {
    final url = Uri.parse(APIConstants.endCurrentStreak);

    final now = DateTime.now().toUtc();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final bool isWithinLast3Days = user.lastMatch.isAfter(threeDaysAgo);

    if (isWithinLast3Days) return;

    print('posting to end current streak');
    UserRepository.instance.currentUser.currentStreak = 0;

    // only post to the api if it is not within the past 3 days
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': UserRepository.instance.currentUser.id,
      }),
    );
  }
}