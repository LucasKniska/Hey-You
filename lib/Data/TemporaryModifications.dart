

class TemporaryModification {

  TemporaryModification({required this.start, required this.modification});

  TemporaryModification.fromJson(Map<String, dynamic> json) :
    this.start = DateTime.parse(json['start']),
    this.modification = json['modification'];


  final DateTime start;
  final String modification;


  Map<String, String> toJson() {
    return {
      'start': start.toIso8601String(),
      'modification': modification
    };
  }

}

