


import 'package:geolocator/geolocator.dart';

import 'QuizQuestions.dart';

class CurrentMatch {

  CurrentMatch({
    required this.id, required this.createdOn, required this.userIds,
    required this.userBios, required this.related, required this.spark, required this.possibleTimes, required this.possiblePlaces, required this.meetNowPlace
  });

  String id;
  DateTime createdOn; // Used to see when match should be closed
  List<String> userIds;
  List<String> userBios;
  List<Question> related;

  List<bool> spark;
  List<DateTime> possibleTimes;
  List<Position> possiblePlaces;
  Position meetNowPlace;

  @override
  String toString(){
    return '$id $createdOn';
  }
}