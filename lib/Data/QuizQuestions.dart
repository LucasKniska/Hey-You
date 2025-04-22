
final List<Question> questionList = <Question>[
  Question(title: 'I enjoy trying new things, even if they\'re outside my comfort zone.', answer: 0),
  Question(title: 'I often find myself thinking deeply about life or the universe.', answer: 0),
  Question(title: 'I feel energized after spending time with other people.', answer: 0),
  Question(title: 'I prefer having a clear plan rather than going with the flow.', answer: 0),
  Question(title: 'I find it easy to empathize with how others are feeling.', answer: 0)
];


class Question {

  final String title;
  int answer;

  Question({required this.title, required this.answer});

}