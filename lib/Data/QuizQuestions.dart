
final List<Question> questionList = <Question>[
  Question(title: 'I enjoy trying new things, even if they\'re outside my comfort zone.'),
  Question(title: 'I often find myself thinking deeply about life or the universe.'),
  Question(title: 'I feel energized after spending time with other people.'),
  Question(title: 'I prefer having a clear plan rather than going with the flow.'),
  Question(title: 'I find it easy to empathize with how others are feeling.')
];


class Question {

  final String title;
  int? answer;

  Question({required this.title, this.answer});

}