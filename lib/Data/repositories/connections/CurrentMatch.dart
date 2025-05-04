import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class CurrentMatch {
  final DateTime createdOn;
  final DateTime expirationTime;
  final String id;
  final List<String> possiblePlaces;
  final List<DateTime> possibleTimes;
  final List<String> related;
  final List<UserData> userData;
  final String? currentProposedPlace;

  CurrentMatch({
    required this.createdOn,
    required this.expirationTime,
    required this.id,
    required this.possiblePlaces,
    required this.possibleTimes,
    required this.related,
    required this.userData,
    this.currentProposedPlace
  });

  factory CurrentMatch.fromJson(Map<String, dynamic> json) {
    return CurrentMatch(
      createdOn: (json['createdOn'] as Timestamp).toDate(),
      expirationTime: (json['expirationTime'] as Timestamp).toDate(),
      id: json['id'],
      currentProposedPlace: json['currentProposedPlace'],
      possiblePlaces: List<String>.from(json['possiblePlaces'] ?? []),
      possibleTimes: (json['possibleTimes'] as List? ?? [])
          .map((t) => (t as Timestamp).toDate())
          .toList(),
      related: List<String>.from(json['related'] ?? []),
      userData: (json['userData'] as List? ?? [])
          .map((u) => UserData.fromJson(u))
          .toList()
    );
  }

  @override
  String toString() {
    return '$createdOn, $related, $id';
  }

  @override
  bool operator ==(Object o) {

    final CurrentMatch other = o as CurrentMatch;

    return (id == other.id && listEquals(possiblePlaces, other.possiblePlaces)
        && listEquals(possibleTimes, other.possibleTimes) && userData[0] == other.userData[0] && userData[1] == other.userData[1] && currentProposedPlace == other.currentProposedPlace);



  }


}

class UserData {
  final String id;
  final String response;
  final String userBio;
  final String userName;

  UserData({
    required this.id,
    required this.response,
    required this.userBio,
    required this.userName,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      response: json['response'],
      userBio: json['userBio'] ?? '',
      userName: json['userName'],
    );
  }

  @override
  bool operator ==(Object o) {
    final UserData other = o as UserData;
    return (other.userName == userName && other.response == response && other.userBio == userBio && other.id == id);
  }


}