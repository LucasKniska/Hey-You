

List<PreviousMatch> previousMatches = [PreviousMatch(), PreviousMatch(), PreviousMatch()];


class PreviousMatch {

  String id = "0913845sjadf";

  Map<String, Map<String, String>> userData = {
    "user1": {
      "userName": "Lucas K",
      'userBio': 'User Bio',
      'id': '398uaisjdflka',
    },
    'user2': {
      'userName': "Carmelo K",
      'userBio': 'Uesr Bio',
      'id': '239845uasdjf',
    }
  };

  List<String> related = ["Economics", 'Exploring NYC'];

  DateTime createdOn = DateTime(2025, 4, 14);
  DateTime connectedOn = DateTime(2025, 4, 15);
  Map<String, String> location = {
    'lat': '23',
    'long': '23',
    'title': 'Columbia'
  };
}