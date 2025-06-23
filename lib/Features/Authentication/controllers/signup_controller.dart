
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/navigation_menu.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/Authentication/screens/signup.dart';

import '../../../Data/models/UserModel.dart';
import '../../../Data/repositories/user/user_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/theme/snackbars.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  /// Variables
  final email = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();

  final hidePassword = true.obs;
  final agreeToTerms = false.obs;
  final rememberMe = false.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();


  /// Sign Up Function
  Future<void> signup() async {
    try {


      // Validate form
      if(!signupFormKey.currentState!.validate()) return;

      if (!agreeToTerms.value) {
        Get.snackbar('Agree to terms of service', 'Agree to the service to sign up');
        return;
      }

      // Loading screen
      Get.to(const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white))));

      // Do internet check



      // Storing user data
      final userCredential = await AuthenticationRepository.instance.registerWithEmailAndPassword(email.text.trim(), password.text.trim());

      final newUser = UserModel(
        email: email.text.trim(),
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        id: userCredential.user!.uid, biography: '',
        quizAnswers: [], temporaryModifications: [], permanentModifications: [],
        location: {}, currentMatch: '', scheduledConnections: [], previousConnections: [], totalConnections: 0
      );

      final userRepository = Get.put(UserRepository());
      userRepository.saveUserRecord(newUser);

      currentUser = newUser;

      TSnackBars.successSnackBar(title: 'You have successfully create your account!', message: 'Create as many connections as possible!');

      print('Going to screen redirect');
      await AuthenticationRepository.instance.screenRedirect();
      print('Completed screen redirect');

    } catch (e) {
      Get.offAll(() => SignUpScreen());
      TSnackBars.errorSnackBar(title: 'There has been an error creating your account', message: e.toString());
    }
  }
}