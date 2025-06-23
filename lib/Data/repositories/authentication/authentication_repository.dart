

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hey_you/Features/Authentication/screens/emailVerification.dart';
import 'package:hey_you/Features/PersonalityQuiz/PersonalityQuiz.dart';

import '../../../Common/navigation_menu.dart';
import '../../../Features/Authentication/screens/signin.dart';
import '../../../Features/Authentication/screens/onboarding.dart';
import '../../../utils/theme/snackbars.dart';
import '../user/user_repository.dart';

class AuthenticationRepository extends GetxController{
  static AuthenticationRepository get instance => Get.find();
  final _auth = FirebaseAuth.instance;

  final deviceStorage = GetStorage();

  @override
  void onReady() {
    FlutterNativeSplash.remove();
    screenRedirect();
  }


  Future<void> screenRedirect() async {
    // Local Storage
    deviceStorage.writeIfNull('isFirstTime', true);

    if (!deviceStorage.read('isFirstTime')) {

      if(FirebaseAuth.instance.currentUser != null) {

        /// User is signed in
        try {
          Get.put(UserRepository());
          currentUser = await UserRepository.instance.getUserById(FirebaseAuth.instance.currentUser!.uid);

          if(FirebaseAuth.instance.currentUser!.emailVerified == true){
            if(currentUser.quizAnswers.isEmpty){
              Get.offAll(() => PersonalityQuizPage());
            } else {
              Get.offAll(() => const NavigationMenu());
            }

          }else{
            Get.offAll(EmailVerificationScreen());
          }

        } catch (e) {
          Get.offAll(() => const LoginScreen());
        }

      } else {
        Get.offAll(() => const LoginScreen());
      }
    } else {
      Get.offAll(const OnBoardingScreen());
    }
  }


  /// Register user
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try{
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }

  }

  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);

    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> signOut() async {
    try{
      await FirebaseAuth.instance.signOut();
      Get.to(() => LoginScreen());
    } catch (e) {
      TSnackBars.errorSnackBar(title: 'There has been an error signing out of your account');
    }
  }

  Future<void> sendEmailVerificationLink() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }
}