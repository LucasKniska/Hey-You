
class APIConstants {
  static const String tAPIKey = '';

  /// Endpoints for api
  static const String awsAPI = 'http://52.205.156.87';
  static const String localDev = 'http://10.0.2.2:8000';

  static const String acceptMatch = '$awsAPI/accept-match';
  static const String deleteMatch = '$awsAPI/reject-match';
  static const String updateLocation = '$awsAPI/update-location';
  static const String completeMatch = '$awsAPI/complete-match';
  static const String cancelCompleteMatch = '$awsAPI/cancel-complete-match';
  static const String getPreviousConnections = '$awsAPI/get-previous-connections';
  static const String updateUserData = '$awsAPI/save-user-record';
  static const String updateQuestionAnswers = '$awsAPI/update-question-answers';
  static const String updateUserMatchData = '$awsAPI/update-user-match-data';
  static const String updateSearchFilters = '$awsAPI/update-search-filters';
  static const String createNewUser = '$awsAPI/create-new-user';
  static const String updateUserField = '$awsAPI/update-user-field';
}

class Decisions {
  static String meetNow = 'meet_now';
  static String notSelected = 'not_selected';
}