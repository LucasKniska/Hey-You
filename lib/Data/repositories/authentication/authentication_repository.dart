

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hey_you/Common/notification_for_match.dart';
import 'package:hey_you/Features/Authentication/screens/emailVerification.dart';

import '../../../Common/location_services.dart';
import '../../../Common/navigation_menu.dart';
import '../../../Features/Authentication/screens/signin.dart';
import '../../../Features/Authentication/screens/onboarding.dart';
import '../../../Features/EditProfile/profile_controller.dart';
import '../../../utils/theme/snackbars.dart';
import '../matching/match_repository.dart';
import '../user/user_repository.dart';

class AuthenticationRepository extends GetxController{
  static AuthenticationRepository get instance => Get.find();
  final _auth = FirebaseAuth.instance;

  final deviceStorage = GetStorage();
  bool firstTryLogin = true;

  @override
  void onReady() {
    FlutterNativeSplash.remove();
    screenRedirect();
    firstTryLogin = false;
  }


  void screenRedirect() {
    // Local Storage
    deviceStorage.writeIfNull('isFirstTime', true);

    if (!deviceStorage.read('isFirstTime')) {

      if(FirebaseAuth.instance.currentUser != null) {

        /// User is signed in
        try {
          if(FirebaseAuth.instance.currentUser!.emailVerified == true){

            Get.put(MatchRepository(), permanent: true);
            if(firstTryLogin){
              Get.put(UserRepository());
            }
            Get.put(LocationController(), permanent: true);
            Get.put(ProfileController(), permanent: true);
            setupNotification();

            Get.offAll(() => const NavigationMenu());
          }else{
            Get.offAll(EmailVerificationScreen());
          }

        } catch (e) {
          print(e);
          Get.offAll(() => const LoginScreen());
        }

      } else {
        print('Firebase Auth isntance empty ${FirebaseAuth.instance.currentUser}');
        Get.offAll(() => const LoginScreen());
      }
    } else {
      Get.offAll(const OnboardingPage());
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

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password).then((UserCredential result) {
        UserRepository.instance.startListeningToUser();
      });    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> signOut() async {
    try{

      UserRepository.instance.stopListeningToUser();
      MatchRepository.instance.stopListeningToMatches();
      UserRepository.instance.currentUser.discoverable = false;
      await UserRepository.instance.saveUserRecord();
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      Get.offAll(() => LoginScreen());
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