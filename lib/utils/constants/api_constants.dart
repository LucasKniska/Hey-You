
class APIConstants {
  static const String tAPIKey = '';

  /// Endpoints for api
  static const String awsAPI = 'http://52.205.156.87';
  static const String localDev = 'http://10.0.2.2:8000';

  static const String acceptMatch = '$localDev/accept-match';
  static const String deleteMatch = '$localDev/reject-match';
  static const String updateLocation = '$localDev/update-location';
  static const String completeMatch = '$localDev/complete-match';
  static const String cancelCompleteMatch = '$localDev/cancel-complete-match';
  static const String getPreviousConnections = '$localDev/get-previous-connections';
  static const String updateUserData = '$localDev/save-user-record';
  static const String updateQuestionAnswers = '$localDev/update-question-answers';
  static const String updateUserMatchData = '$localDev/update-user-match-data';
  static const String updateSearchFilters = '$localDev/update-search-filters';
  static const String createNewUser = '$localDev/create-new-user';
  static const String updateUserField = '$localDev/update-user-field';
}

class Decisions {
  static String meetNow = 'meet_now';
  static String notSelected = 'not_selected';
}