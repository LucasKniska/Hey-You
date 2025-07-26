
class APIConstants {
  static const String tAPIKey = '';

  /// Endpoints for api
  static const String imperial = 'http://192.168.1.8:8000';
  static const String lakeview = 'http://192.168.1.120:8000';
  static const String base3 = 'http://10.0.2.2:8000';

  static const String acceptMatch = '$base3/accept-match';
  static const String deleteMatch = '$base3/reject-match';
  static const String updateLocation = '$base3/update-location';
  static const String completeMatch = '$base3/complete-match';
  static const String cancelCompleteMatch = '$base3/cancel-complete-match';
  static const String getPreviousConnections = '$base3/get-previous-connections';
  static const String updateUserData = '$base3/save-user-record';
  static const String updateQuestionAnswers = '$base3/update-question-answers';
  static const String updateUserMatchData = '$base3/update-user-match-data';
  static const String updateSearchFilters = '$base3/update-search-filters';
  static const String createNewUser = '$base3/create-new-user';
  static const String updateUserField = '$base3/update-user-field';
}

class Decisions {
  static String meetNow = 'meet_now';
  static String notSelected = 'not_selected';
}