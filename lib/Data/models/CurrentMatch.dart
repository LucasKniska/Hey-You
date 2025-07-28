import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CurrentMatch {
  DateTime createdOn;
  DateTime expirationTime;
  final String id;
  final List<String> possiblePlaces;
  final List<DateTime> possibleTimes;
  final List<String> related;
  final List<UserData> userData;
  String status;
  double distance;

  CurrentMatch({
    required this.createdOn,
    required this.expirationTime,
    required this.id,
    required this.possiblePlaces,
    required this.possibleTimes,
    required this.related,
    required this.userData,
    required this.status,
    required this.distance
  });

  factory CurrentMatch.fromJson(Map<String, dynamic> json) {
    return CurrentMatch(
      createdOn: DateTime.parse(json['createdOn']),
      expirationTime: DateTime.parse(json['expirationTime']),
      id: json['id'],
      possiblePlaces: List<String>.from(json['possiblePlaces'] ?? []),
      possibleTimes: (json['possibleTimes'] as List? ?? [])
          .map((t) => (t as Timestamp).toDate())
          .toList(),
      related: List<String>.from(json['related'] ?? []),
      userData: (json['userData'] as List? ?? [])
          .map((u) => UserData.fromJson(u))
          .toList(),
      status: json['status'],
      distance: json['distance'].toDouble() ?? 0.0
    );
  }

  factory CurrentMatch.fromSame(CurrentMatch c){
    return CurrentMatch(createdOn: c.createdOn, expirationTime: c.expirationTime, id: c.id,
        possiblePlaces: c.possiblePlaces, possibleTimes: c.possibleTimes, related: c.related,
        userData: c.userData, status: c.status, distance: c.distance);
  }


  Map<String, dynamic> toJson() {
    return {
      'createdOn': createdOn.toString(),
      'expirationTime': expirationTime.toString(),
      'id': id,
      'possiblePlaces': possiblePlaces,
      'possibleTimes': possibleTimes.map((d) => Timestamp.fromDate(d)).toList(),
      'related': related,
      'userData': userData.map((u) => u.toJson()).toList(),
      'status': status,
      'distance': distance
    };
  }

  @override
  String toString() {
    return '$createdOn, $expirationTime, $related, $id, ${userData[0]}, ${userData[1]}, $status, distance: $distance';
  }

  @override
  bool operator ==(Object o) {
    final CurrentMatch other = o as CurrentMatch;

    return (id == other.id && distance == other.distance&& listEquals(possiblePlaces, other.possiblePlaces) && status == other.status
        && listEquals(possibleTimes, other.possibleTimes) && userData[0] == other.userData[0] && userData[1] == other.userData[1]);
  }
}

class UserData {
  String id;
  String response;
  String userBio;
  String userName;
  Map<String, double> location;
  int connections;

  UserData({
    required this.id,
    required this.response,
    required this.userBio,
    required this.userName,
    required this.location,
    this.connections=0
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      response: json['response'],
      userBio: json['userBio'] ?? '',
      userName: json['userName'],
      location: Map<String, double>.from(json['location']?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {}),
      connections: json['connections'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'response': response,
      'userBio': userBio,
      'userName': userName,
      'location': location,
      'connections': connections
    };
  }


  @override
  String toString() {
    return '$id, $userName, $response, connections: $connections';
  }

  @override
  bool operator ==(Object o) {
    final UserData other = o as UserData;
    return (location['lat'] == other.location['lat'] && location['long'] == other.location['long'] && other.userName == userName && other.response == response && other.userBio == userBio && other.id == id);
  }


}