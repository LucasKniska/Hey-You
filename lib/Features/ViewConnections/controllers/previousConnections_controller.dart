
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:http/http.dart' as http;

import '../../../Data/models/PreviousMatch.dart';
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

      currentUser.totalConnections = connections.length;
      // Convert each entry into a PreviousMatch
      return connections.map((json) => PreviousMatch.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch previous matches. Status code: ${response.statusCode}");
    }

    return [];
  }
}