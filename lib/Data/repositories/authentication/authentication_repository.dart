

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hey_you/Data/models/QuizQuestions.dart';
import 'package:hey_you/Features/Authentication/screens/emailVerification.dart';

import '../../../Common/location_services.dart';
import '../../../Common/navigation_menu.dart';
import '../../../Features/Authentication/screens/signin.dart';
import '../../../Features/Authentication/screens/onboarding.dart';
import '../../../Features/Authentication/screens/usernameAndBio.dart';
import '../../../Features/EditProfile/profile_controller.dart';
import '../../../Features/Onboarding/TermsOfService.dart';
import '../../../Features/PersonalityQuiz/PersonalityQuiz.dart';
import '../../../Features/ViewConnections/previousConnections.dart';
import '../../models/UserModel.dart';
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
    screenRedirect(false);
    firstTryLogin = false;
  }


  Future<void> screenRedirect(bool newUser) async {

    if (deviceStorage.read('isFirstTime') == null || deviceStorage.read('isFirstTime') == false) {

      if(FirebaseAuth.instance.currentUser != null) {

        /// User is signed in
        try {
          print('New User: $newUser');
          if(FirebaseAuth.instance.currentUser!.emailVerified == true){

            if(newUser){
              // Show terms of service
              final accepted = await Get.to(() => TermsOfService());

              if (accepted != true) {
                // User did not accept terms — delete account and sign out
                await FirebaseAuth.instance.currentUser?.delete();
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
                // Show create user name and biography screen
                return;
              }
            }


            Get.put(MatchRepository(), permanent: true);
            Get.put(UserRepository());
            Get.put(ProfileController(), permanent: true);
            Get.put(LocationController(), permanent: true);
            UserRepository.instance.startListeningToUser();

            if(newUser){
              await Get.to(() => UserNameAndBio());
              print('Putting personality quiz page');
              await Get.to(() => const PersonalityQuizPage());
              LocationController.instance.singleUpdate();
              Get.offAll(() => const NavigationMenu());
            } else {
              Get.offAll(() => const NavigationMenu());
            }


          }else{
            Get.offAll(EmailVerificationScreen());
          }

        } catch (e) {
          print(e);
          Get.offAll(() => const LoginScreen());
        }

      } else {
        print('Firebase Auth instance empty ${FirebaseAuth.instance.currentUser}');
        Get.offAll(() => const LoginScreen());
      }
    } else {
      Get.offAll(() => const OnboardingPage());
      // Local Storage
      deviceStorage.write('isFirstTime', false);
    }
  }

  Future<bool?> loginWithGoogle() async {
    try{
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;

      final cred = GoogleAuthProvider.credential(idToken: googleAuth?.idToken, accessToken: googleAuth?.accessToken);

      final firebaseCred = await _auth.signInWithCredential(cred);

      var userId = firebaseCred.user!.uid; // Replace with the actual user ID
      var userDocRef = FirebaseFirestore.instance.collection("Users").doc(userId);

      // Identifies as a new user
      if(await userDocRef.get().then((doc) => !doc.exists)) {
        UserModel newUser = UserModel.initial();
        newUser.id = FirebaseAuth.instance.currentUser!.uid;

        final userRepository = UserRepository.instance;
        userRepository.createNewUser(newUser);
        return true;
      }
      return false;

    } catch(e) {

      print('Authentication Repository Error: ${e.toString()}');
    }

    return null;
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
        print('Result of signin: ${result.user}');
        UserRepository.instance.startListeningToUser();
      });    } catch (e) {
      print(e);
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> signOut() async {
    try{
      firstTryLogin = true;
      UserRepository.instance.stopListeningToUser();
      MatchRepository.instance.stopListeningToMatches();
      UserRepository.instance.currentUser.discoverable = false;
      UserRepository.instance.updateUserField('discoverable', false);

      questionList.forEach((element) {
        element.answer = element.type == 2 ? 0 : '';
      });

      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

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