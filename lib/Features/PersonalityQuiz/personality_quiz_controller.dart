

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

    for(int i = 0; i < questionList.length; i++){
      questionList[i].answer = currentUser.quizAnswers[i];
    }

  }

  Future<void> submitQuiz() async {
    // Update currentUser
    // Update online database

    // Loading screen
    try {
      Get.to(const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white))));

      currentUser.quizAnswers = questionList.map((e) => e.answer).toList();

      final userRepository = Get.put(UserRepository());
      userRepository.saveUserRecord(currentUser);

      TSnackBars.successSnackBar(title: 'You have successfully updated your personality quiz answers!', message: '');


      Get.offAll(() => NavigationMenu());
    } on Exception catch (e) {
      Get.offAll(() => PersonalityQuizPage());
      TSnackBars.errorSnackBar(title: 'There has been an error submitting the quiz', message: '');

    }

  }

}