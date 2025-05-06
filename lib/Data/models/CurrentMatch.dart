import 'package:cloud_firestore/cloud_firestore.dart';
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
      createdOn: DateTime.parse(json['createdOn']),
      expirationTime: DateTime.parse(json['expirationTime']),
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


  Map<String, dynamic> toJson() {
    return {
      'createdOn': createdOn.toString(),
      'expirationTime': expirationTime.toString(),
      'id': id,
      'currentProposedPlace': currentProposedPlace,
      'possiblePlaces': possiblePlaces,
      'possibleTimes': possibleTimes.map((d) => Timestamp.fromDate(d)).toList(),
      'related': related,
      'userData': userData.map((u) => u.toJson()).toList(),
    };
  }


  @override
  String toString() {
    return '$createdOn, $related, $id, ${userData[0]}, ${userData[1]}';
  }

  @override
  bool operator ==(Object o) {

    final CurrentMatch other = o as CurrentMatch;

    return (id == other.id && listEquals(possiblePlaces, other.possiblePlaces)
        && listEquals(possibleTimes, other.possibleTimes) && userData[0] == other.userData[0] && userData[1] == other.userData[1] && currentProposedPlace == other.currentProposedPlace);
  }
}

class UserData {
  String id;
  String response;
  String userBio;
  String userName;
  Map<String, double> location;

  UserData({
    required this.id,
    required this.response,
    required this.userBio,
    required this.userName,
    required this.location
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      response: json['response'],
      userBio: json['userBio'] ?? '',
      userName: json['userName'],
      location: Map<String, double>.from(json['location']?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'response': response,
      'userBio': userBio,
      'userName': userName,
      'location': location
    };
  }


  @override
  String toString() {
    return '$id, $response';
  }

  @override
  bool operator ==(Object o) {
    final UserData other = o as UserData;
    return (other.userName == userName && other.response == response && other.userBio == userBio && other.id == id);
  }


}