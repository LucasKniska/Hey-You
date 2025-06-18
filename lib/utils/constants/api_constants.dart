

// Example
class APIConstants {
  static const String tAPIKey = '';

  /// Endpoints for api
  static const String base = 'http://192.168.1.8:8000';
  static const String base2 = 'http://192.168.1.120:8000';

  static const String updateMatchStatus = '$base/accept-match';
  static const String deleteMatch = '$base/reject-match';
  static const String updateLocation = '$base/update-location';
  static const String completeMatch = '$base/complete-match';
  static const String cancelCompleteMatch = '$base/cancel-complete-match';
  static const String getPreviousConnections = '$base/get-previous-connections';
}