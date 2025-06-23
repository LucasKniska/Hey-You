import 'package:flutter/material.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Features/PersonalityQuiz/personality_quiz_controller.dart';

import '../../Common/styles/spacing_styles.dart';
import '../../Data/models/QuizQuestions.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_string.dart';

class PersonalityQuizPage extends StatefulWidget {
  const PersonalityQuizPage({super.key});

  @override
  State<PersonalityQuizPage> createState() => _PersonalityQuizPageState();
}

class _PersonalityQuizPageState extends State<PersonalityQuizPage> {
  final PersonalityQuizController controller = PersonalityQuizController();
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    controller.initAnswers();
  }

  void _setAnswer(int pageIndex, int value) {
    setState(() {
      controller.setAnswer(pageIndex, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(),
      body: SafeArea(
        child: Column(
          children: [
            /// Notes and progress
            Padding(
              padding: TSpacingStyle.normalPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TTexts.quizTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TTexts.quizUnder,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Question ${currentPage + 1} of ${questionList.length}'),
                      Text('${((currentPage + 1) / questionList.length * 100).round()}% Complete'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (currentPage + 1) / questionList.length,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            /// Quiz content
            Expanded(
              child: PageView.builder(
                itemCount: questionList.length,
                onPageChanged: (index) {
                  setState(() => currentPage = index);
                },
                itemBuilder: (context, index) {
                  final question = questionList[index];

                  /// Submit button on final page
                  Widget submitForm(int index) {
                    if (index == questionList.length - 1) {
                      return Column(
                        children: [
                          const SizedBox(height: TSizes.spaceBtwItems),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                controller.submitQuiz();
                              },
                              child: Text(TTexts.submitQuiz),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: TColors.secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            question.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(5, (i) => i + 1).map(
                              (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: question.answer == i
                                  ? OutlinedButton(
                                onPressed: () => _setAnswer(index, i),
                                child: Text('$i'),
                              )
                                  : ElevatedButton(
                                onPressed: () => _setAnswer(index, i),
                                child: Text('$i'),
                              ),
                            ),
                          ),
                        ),
                        submitForm(index),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
