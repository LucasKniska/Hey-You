import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/Authentication/screens/signin.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../Common/styles/spacing_styles.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {

  final _auth = AuthenticationRepository.instance;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    _auth.sendEmailVerificationLink();

    timer = Timer.periodic(Duration(seconds:5), (timer) {
      FirebaseAuth.instance.currentUser?.reload();
      if(FirebaseAuth.instance.currentUser!.emailVerified){
        print('Email is verified');
        timer.cancel();
        _auth.screenRedirect(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: TSpacingStyle.normalPadding,
              child: Stack(
                children: [
                  /// Back button
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Iconsax.arrow_left_3),
                        onPressed: () {
                          Get.offAll(() => const LoginScreen());
                        },
                      ),
                    ),
                  ),

                  /// Main Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// Email Icon
                      const Icon(
                        Iconsax.direct_send,
                        size: 80,
                        color: TColors.primary,
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      /// Header Text
                      Text(
                        'Verify Your Email',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: TSizes.sm),

                      /// Subtext
                      Text(
                        "We've sent a verification link to your email. Please check your inbox and click the link to activate your account.",
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      /// Resend Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Iconsax.refresh_circle),
                          label: const Text("Resend Email"),
                          onPressed: () {
                            _auth.sendEmailVerificationLink();
                          },
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      /// Go to Login
                      TextButton(
                        onPressed: () {
                          Get.offAll(() => const LoginScreen());
                        },
                        child: Text(
                          "Back to Login",
                          style: TextStyle(color: TColors.primary),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}
