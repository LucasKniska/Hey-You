

import 'package:hey_you/Data/TemporaryModifications.dart';

import 'PreviousMatch.dart';

class UserModel {

  UserModel({required this.email, required this.firstName, required this.lastName, required this.id, required this.biography,
    required this.quizAnswers, required this.temporaryModifications, required this.permanentModifications, required this.location,
    required this.currentMatch, required this.scheduledConnections, required this.previousConnections, required this.totalConnections
  });

  UserModel.initial()
    : id = '',
      email = '',
      firstName = '',
      lastName = '',
      biography = '',
      quizAnswers = [],
      temporaryModifications = [],
      permanentModifications = [],
      location = {},
      currentMatch = '',
      previousConnections = [],
      scheduledConnections = [],
      totalConnections = 0;

  UserModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        email = json['Email'] as String,
        firstName = json['FirstName'] as String,
        lastName = json['LastName'] as String,
        biography = json['Biography'] as String,
        quizAnswers = (json['QuizAnswers'] as List).map((e) => e as int).toList(),
        temporaryModifications = (json['TemporaryModifications'] as List)
            .map((e) => new TemporaryModification.fromJson(e))
            .toList(),
        permanentModifications = (json['PermanentModifications'] as List).map((e) => e as String).toList(),
        location = Map<String, dynamic>.from(json['Location'] as Map),
        currentMatch = json['CurrentMatch'] as String,
        scheduledConnections = (json['ScheduledConnections'] as List).map((e) => e as String).toList(),
        previousConnections = (json['PreviousConnections'] as List).map((e) => e as String).toList(),
        totalConnections = json['TotalConnections'] as int;


  String id;

  String email;
  String firstName;
  String lastName;
  String biography;
  List<int> quizAnswers;

  List<TemporaryModification> temporaryModifications; // Need to know modification and time it was created

  List<String> permanentModifications;
  Map<String, dynamic> location;

  String currentMatch;

  List<String> scheduledConnections;
  List<String> previousConnections;

  int totalConnections;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'Biography': biography,
      'QuizAnswers': quizAnswers,
      'TemporaryModifications': temporaryModifications.map((e) => e.toJson()),
      'PermanentModifications': permanentModifications,
      'Location': location,
      'CurrentMatch': currentMatch,
      'ScheduledConnections': scheduledConnections,
      'PreviousConnections': previousConnections,
      'TotalConnections': totalConnections
    };
  }


  @override
  String toString(){
    return '$firstName $lastName';
  }

}