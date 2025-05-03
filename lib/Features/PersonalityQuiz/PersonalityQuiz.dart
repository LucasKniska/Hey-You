import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hey_you/Common/navigation_menu.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/Features/PersonalityQuiz/personality_quiz_controller.dart';

import '../../Common/styles/spacing_styles.dart';
import '../../Data/repositories/connections/QuizQuestions.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_string.dart';
import '../ViewConnections/ContactsPage.dart';

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
      body: Column(
        children: [
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
                      SizedBox(height: 4),
                      Text(
                          TTexts.quizUnder,
                          style: Theme.of(context).textTheme.bodySmall
                      ),
                    ],
                  ),
                ),

                SizedBox(height: TSizes.spaceBtwSections),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${currentPage + 1} of ${questionList.length}'),
                    Text('${((currentPage + 1) / questionList.length * 100).round()}% Complete'),
                  ],
                ),

                LinearProgressIndicator(
                  value: (currentPage + 1) / questionList.length,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                ),
              ],
            ),
          ),

          SizedBox(
            height: 600,
            child: PageView.builder(

              itemCount: questionList.length,
              onPageChanged: (index) {
                setState(() => currentPage = index);
              },
              itemBuilder: (context, index) {
                final question = questionList[index];

                /// Submit button on final page of the form
                Widget submitForm(int index) {
                  if(index == questionList.length-1) {
                    return Column(

                      children: [
                        SizedBox(height: TSizes.spaceBtwItems),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () { controller.submitQuiz(); },
                            child: Text(TTexts.submitQuiz),
                          ),
                        ),
                      ],
                    );
                  }

                  return Container();
                }


                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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

                      Spacer(),

                      submitForm(index) /// Submit button if it is the last question

                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}