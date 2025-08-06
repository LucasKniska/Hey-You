import 'package:hey_you/Data/TemporaryModifications.dart';

class UserModel {
  String id;
  String email;
  String firstName;
  String lastName;
  String biography;
  Map<String, dynamic> quizAnswers;

  List<TemporaryModification> temporaryModifications;
  List<String> permanentModifications;
  Map<String, double> location;

  String currentMatch;

  int totalConnections;
  bool discoverable;
  int longestStreak;
  int currentStreak;
  DateTime lastMatch;

  UserModel({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.id,
    required this.biography,
    required this.quizAnswers,
    required this.temporaryModifications,
    required this.permanentModifications,
    required this.location,
    required this.currentMatch,
    required this.totalConnections,
    required this.discoverable,
    required this.longestStreak,
    required this.currentStreak,
    required this.lastMatch,
  });

  UserModel.initial()
      : id = '',
        email = '',
        firstName = '',
        lastName = '',
        biography = '',
        quizAnswers = <String, int>{},
        temporaryModifications = [],
        permanentModifications = [],
        location = {},
        currentMatch = '',
        totalConnections = 0,
        discoverable = false,
        longestStreak = 0,
        currentStreak = 0,
        lastMatch = DateTime.now();

  UserModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String? ?? '',
        email = json['Email'] as String? ?? '',
        firstName = json['FirstName'] as String? ?? '',
        lastName = json['LastName'] as String? ?? '',
        biography = json['Biography'] as String? ?? '',
        quizAnswers = (json['QuestionAnswers'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(json['QuestionAnswers'])
            : {},
        temporaryModifications = (json['TemporaryModifications'] as List<dynamic>?)
            ?.map((e) => TemporaryModification.fromJson(e))
            .toList() ??
            [],
        permanentModifications = (json['PermanentModifications'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
            [],
        location = (json['Location'] != null)
            ? Map<String, double>.from(json['Location'] as Map)
            : {},
        currentMatch = json['CurrentMatch'] as String? ?? '',
        totalConnections = json['TotalConnections'] as int? ?? 0,
        discoverable = json['Discoverable'] as bool? ?? false,
        longestStreak = json['LongestStreak'] as int? ?? 0,
        currentStreak = json['CurrentStreak'] as int? ?? 0,
        lastMatch = (json['LastMatch'] != null)
            ? json['LastMatch'].toDate() ?? DateTime.now()
            : DateTime.now();


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'Biography': biography,
      'QuestionAnswers': quizAnswers,
      'TemporaryModifications': temporaryModifications.map((e) => e.toJson()).toList(),
      'PermanentModifications': permanentModifications,
      'Location': location,
      'CurrentMatch': currentMatch,
      'TotalConnections': totalConnections,
      'Discoverable': discoverable,
      'LongestStreak': longestStreak,
      'CurrentStreak': currentStreak,
      'LastMatch': lastMatch.toIso8601String()
    };
  }

  @override
  String toString() {
    return '''
      UserModel(
        id: $id,
        email: $email,
        name: $firstName $lastName,
        biography: ${biography.isEmpty ? '(none)' : biography},
        quizAnswers: $quizAnswers,
        temporaryModifications: [${temporaryModifications.map((mod) => mod.toString()).join(', ')}],
        permanentModifications: $permanentModifications,
        location: $location,
        currentMatch: $currentMatch,
        totalConnections: $totalConnections
      )''';
  }
}
