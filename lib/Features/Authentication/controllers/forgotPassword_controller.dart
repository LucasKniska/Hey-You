import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import '../../../utils/validators/validation.dart';

class ForgotPasswordController extends GetxController {
  final email = TextEditingController();
  final forgotPasswordFormKey = GlobalKey<FormState>();

  String? validateEmail(String? value) {
    return TValidator.validateEmail(value);
  }

  void sendResetEmail() {
    if (!forgotPasswordFormKey.currentState!.validate()) return;

    var _auth = AuthenticationRepository.instance;

    _auth.sendPasswordResetLink(email.text);

  }
}
