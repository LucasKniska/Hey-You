

import 'PreviousMatch.dart';

class UserModel {

  UserModel({required this.email, required this.firstName, required this.lastName, required this.id, this.biography,
    this.quizAnswers, this.temporaryModifications, this.permanentModifications, this.location,
    this.currentMatch, this.scheduledConnections, this.previousConnections
  });

  String id;

  String email;
  String firstName;
  String lastName;
  String? biography;
  List<int>? quizAnswers;

  List<Map<String, Object>>? temporaryModifications;

  List<String>? permanentModifications;
  Map<String, Object>? location;

  PreviousMatch? currentMatch;

  List<String>? scheduledConnections;
  List<String>? previousConnections;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'Biography': biography,
      'QuizAnswers': quizAnswers,
      'TemporaryModifications': temporaryModifications,
      'PermanentModifications': permanentModifications,
      'Location': location,
      'CurrentMatch': currentMatch,
      'ScheduledConnections': scheduledConnections,
      'PreviousConnections': previousConnections
    };

  }

}