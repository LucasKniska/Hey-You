

// Example
class APIConstants {
  static const String tAPIKey = '';

  /// Endpoints for api
  static const String updateMatchStatus = 'http://192.168.1.120:8000/accept-match';
  static const String deleteMatch = 'http://192.168.1.120:8000/reject-match';
  static const String updateLocation = 'http://192.168.1.120:8000/update-location';
  static const String completeMatch = 'http://192.168.1.120:8000/complete-match';
  static const String cancelCompleteMatch = 'http://192.168.1.120:8000/cancel-complete-match';
}