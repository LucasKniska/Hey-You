
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/Authentication/controllers/signin_controller.dart';
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

  Future<void> googleSignUp() async {
    var controller = SignInController();
    await controller.signinGoogle();
  }

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
      await AuthenticationRepository.instance.registerWithEmailAndPassword(email.text.trim(), password.text.trim());

      UserModel newUser = UserModel.initial();
      newUser.email = email.text.trim();
      newUser.firstName = firstName.text.trim();
      newUser.lastName = lastName.text.trim();
      newUser.id = FirebaseAuth.instance.currentUser!.uid;

      final userRepository = Get.put(UserRepository());
      userRepository.createNewUser(newUser);

      Get.offAll(() => SignUpScreen());

      TSnackBars.successSnackBar(title: 'You have successfully create your account!', message: 'Create as many matching as possible!');

      AuthenticationRepository.instance.screenRedirect(true);

    } on FirebaseAuthException catch (e) {
      Get.offAll(() => SignUpScreen());

      if (e.code == 'email-already-in-use') {
        TSnackBars.errorSnackBar(title: 'The email: "${email.text}" is already in use.', message: 'Try signing up or forgot password.');
      } else {
        TSnackBars.errorSnackBar(title: 'There has been an error creating your account', message: e.toString());
      }
    } catch (e) {
      Get.offAll(() => SignUpScreen());
      TSnackBars.errorSnackBar(title: 'There has been an error creating your account', message: e.toString());
    }
  }
}