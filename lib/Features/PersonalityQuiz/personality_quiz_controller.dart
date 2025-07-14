

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/Features/PersonalityQuiz/PersonalityQuiz.dart';

import '../../Common/navigation_menu.dart';
import '../../Data/models/QuizQuestions.dart';
import '../../utils/constants/colors.dart';
import '../../utils/theme/snackbars.dart';

class PersonalityQuizController {


  Map<String, TextEditingController> textControllers = {};

  void setAnswer(int pageIndex, dynamic value){
      questionList[pageIndex].answer = value;
  }

  void initAnswers() {

    if (currentUser.quizAnswers.isNotEmpty){
      for(int i = 0; i < questionList.length; i++){
        if(currentUser.quizAnswers[questionList[i].key] != null){


          if(currentUser.quizAnswers[questionList[i].key].runtimeType == String){
            textControllers.putIfAbsent(questionList[i].key, () => TextEditingController(text: currentUser.quizAnswers[questionList[i].key]));
            questionList[i].answer = currentUser.quizAnswers[questionList[i].key];

          } else {
            questionList[i].answer = currentUser.quizAnswers[questionList[i].key]!%10;
          }

        } else if (questionList[i].type == 0) {
          textControllers.putIfAbsent(questionList[i].key, () => TextEditingController());
        }
      }
    }

  }

  Future<void> submitQuiz() async {
    // Update currentUser
    // Update online database

    // Loading screen
    try {
      Get.to(() => const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white))));

      currentUser.quizAnswers = {
        for (final q in questionList)
          q.key: q.type == 0 ? q.answer.toString() : (q.answer ?? 0) + q.type * 10,
      };

      final userRepository = Get.put(UserRepository());

      try {
        await userRepository.updateQuestionAnswers(currentUser);
        TSnackBars.successSnackBar(title: 'You have successfully updated your personality quiz answers!', message: '');
        textControllers.values.forEach((controller) => controller.dispose());
        Get.offAll(() => NavigationMenu());
      } catch (e) {
        Get.back();
        TSnackBars.errorSnackBar(title: 'Could not update your personality quiz answers!', message: 'Please try again.');
      }
    } on Exception catch (e) {
      Get.back();
      TSnackBars.errorSnackBar(title: 'Could not update your personality quiz answers!', message: 'Please try again.');
    }

  }

}