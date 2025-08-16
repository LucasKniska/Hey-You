
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/Features/Authentication/screens/signin.dart';
import 'package:hey_you/utils/theme/snackbars.dart';

import '../../../utils/constants/colors.dart';


class SignInController extends GetxController {
  static SignInController get instance => Get.find();

  /// Variables
  final email = TextEditingController();
  final password = TextEditingController();

  final hidePassword = true.obs;
  final rememberMe = false.obs;

  GlobalKey<FormState> signinFormKey = GlobalKey<FormState>();

  final localStorage = GetStorage();


  @override
  void onInit() {
    super.onInit();

    try{
      email.text = localStorage.read('REMEMBER_EMAIL');
      password.text = localStorage.read('REMEMBER_PASSWORD');

      if(email.text != ''){
        rememberMe.value = true;
      }
    } catch (e) {
      rememberMe.value = false;
    }

  }

  Future<void> signinGoogle() async {

    try {

      Get.to(() => const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white))));

      Get.put(UserRepository());

      final newUser = await AuthenticationRepository.instance.loginWithGoogle();
      print('Sign In Controller New User: $newUser');
      AuthenticationRepository.instance.screenRedirect(newUser!);
    } catch (e) {
      Get.offAll(() => LoginScreen());
      print('Sign In Controller Error: $e');
      TSnackBars.errorSnackBar(title: 'There has been an error signing into your account');
    }
  }

  /// Sign Up Function
  Future<void> signin() async {
    try {
      // Validate form
      if(!signinFormKey.currentState!.validate()) return;

      // Loading screen
      Get.to(() => const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white))));

      // TODO Do internet check

      print('Putting user repo');
      Get.put(UserRepository());

      print('Login with email and password');
      await AuthenticationRepository.instance.loginWithEmailAndPassword(email.text.trim(), password.text.trim());

      if (rememberMe.value) {
        localStorage.write('REMEMBER_EMAIL', email.text.trim());
        localStorage.write('REMEMBER_PASSWORD', password.text.trim());
      } else {
        localStorage.write('REMEMBER_EMAIL', '');
        localStorage.write('REMEMBER_PASSWORD', '');
      }

      print('Going to screen redirect');
      AuthenticationRepository.instance.screenRedirect(false);
      print('Completed screen redirect');

    } catch (e) {
      Get.offAll(() => LoginScreen());
      TSnackBars.errorSnackBar(title: 'There has been an error signing into your account');
    }
  }
}