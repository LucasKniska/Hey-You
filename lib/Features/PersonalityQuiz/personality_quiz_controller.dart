

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/Features/PersonalityQuiz/PersonalityQuiz.dart';

import '../../Common/navigation_menu.dart';
import '../../Data/models/QuizQuestions.dart';
import '../../utils/constants/colors.dart';
import '../../utils/theme/snackbars.dart';

class PersonalityQuizController {

  void setAnswer(int pageIndex, int value){
      questionList[pageIndex].answer = value;
  }

  void initAnswers() {

    if (currentUser.quizAnswers.isNotEmpty){
      for(int i = 0; i < questionList.length; i++){
        if(currentUser.quizAnswers[i.toString()] != null){
          questionList[i].answer = currentUser.quizAnswers[i.toString()]!%10;
        }
      }
    }
  }

  Future<void> submitQuiz() async {
    // Update currentUser
    // Update online database

    // Loading screen
    try {
      Get.to(const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white))));

      print(questionList[0]);
      print(questionList[1]);
      print(questionList[2]);
      print(questionList[3]);


      currentUser.quizAnswers = {
        for (final q in questionList) q.key: q.answer+q.type*10,
      };

      final userRepository = Get.put(UserRepository());
      userRepository.updateQuestionAnswers(currentUser);

      TSnackBars.successSnackBar(title: 'You have successfully updated your personality quiz answers!', message: '');


      Get.offAll(() => NavigationMenu());
    } on Exception catch (e) {
      Get.offAll(() => PersonalityQuizPage());
      TSnackBars.errorSnackBar(title: 'There has been an error submitting the quiz', message: '');

    }

  }

}