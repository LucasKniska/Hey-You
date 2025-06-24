

import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'CurrentMatch.dart';

class PreviousMatch {
  final String id;
  final List<String> related;
  final DateTime createdOn;
  final DateTime expirationTime;
  final List<UserData> userData;
  final String status;
  final List<String> possiblePlaces;
  final List<DateTime> possibleTimes;
  final Map<String, double> meetingPlace;

  PreviousMatch({
    required this.id,
    required this.related,
    required this.createdOn,
    required this.expirationTime,
    required this.userData,
    required this.status,
    required this.possiblePlaces,
    required this.possibleTimes,
    required this.meetingPlace,
  });

  factory PreviousMatch.fromJson(Map<String, dynamic> json) {
    return PreviousMatch(
      id: json['id'],
      related: List<String>.from(json['related'] ?? []),
      createdOn: DateTime.parse(json['createdOn']),
      expirationTime: DateTime.parse(json['expirationTime']),
      userData: (json['userData'] as List)
          .map((u) => UserData.fromJson(u))
          .toList(),
      status: json['status'] is String
          ? json['status']
          : json['status'].toString().split('.').last, // handles enum format
      possiblePlaces: List<String>.from(json['possiblePlaces'] ?? []),
      possibleTimes: (json['possibleTimes'] as List? ?? [])
          .map((t) => DateTime.parse(t))
          .toList(),
      meetingPlace: Map<String, double>.from(json['meetingPlace']
          .map((k, v) => MapEntry(k, (v as num).toDouble()))),
    );
  }

  String previousConnectionDateDetails() {
    String formatted = DateFormat('MMMM, d y').format(createdOn);
    //TODO Name the created place based on latitude and longitude
    return 'You connected on $formatted @ place';
  }

  String previousConnectionUserDetails(){

    int user = (userData[0].id == FirebaseAuth.instance.currentUser!.uid) ? 1 : 0;

    return '${userData[user].userName} - ${related[0]}';
  }

  @override
  String toString() {
    return 'Previous Match: $id';
  }
}


