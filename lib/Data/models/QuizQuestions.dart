
final List<Question> questionList = <Question>[
  Question(title: 'I feel energized after being around a large group of people.', answer: 0, key: '1', type: 2),
  Question(title: 'I often need time alone to recharge after social events.', answer: 0, key: '2', type: 2),
  Question(title: 'I enjoy initiating conversations with strangers.', answer: 0, key: '3', type: 2),
  Question(title: 'I prefer deep one-on-one talks over group discussions.', answer: 0, key: '4', type: 2),
  Question(title: 'I thrive in fast-paced, lively environments.', answer: 0, key: '5', type: 2),
  Question(title: 'Facts and practical details guide most of my decisions.', answer: 0, key: '6', type: 2),
  Question(title: 'I’m drawn to abstract theories and big-picture ideas.', answer: 0, key: '7', type: 2),
  Question(title: 'I notice subtle sensory details (smells, textures, sounds) that others miss.', answer: 0, key: '8', type: 2),
  Question(title: 'I often ask “What if…?” and imagine future possibilities.', answer: 0, key: '9', type: 2),
  Question(title: 'I prefer hands-on experience to reading instructions.', answer: 0, key: '10', type: 2),
  Question(title: 'I make choices primarily with my head, not my heart.', answer: 0, key: '11', type: 2),
  Question(title: 'I weigh how decisions will affect people’s feelings.', answer: 0, key: '12', type: 2),
  Question(title: 'Critiquing ideas comes naturally to me.', answer: 0, key: '13', type: 2),
  Question(title: 'Harmony in a group is more important than winning an argument.', answer: 0, key: '14', type: 2),
  Question(title: 'I value objective logic over personal values when solving problems.', answer: 0, key: '15', type: 2),
  Question(title: 'I like having decisions settled well in advance.', answer: 0, key: '16', type: 2),
  Question(title: 'I keep my options open until the last possible moment.', answer: 0, key: '17', type: 2),
  Question(title: 'Detailed schedules help me feel in control.', answer: 0, key: '18', type: 2),
  Question(title: 'I’m comfortable adapting plans on the fly.', answer: 0, key: '19', type: 2),
  Question(title: 'I prefer clear rules to spontaneous approaches.', answer: 0, key: '20', type: 2),
];



class Question {

  final String title;
  int answer;
  String key;
  int type;

  Question({required this.title, required this.answer, required this.key, required this.type});

  @override
  String toString() {
    return 'Question(title: $title, answer: $answer, key: $key, type: $type)';
  }
}