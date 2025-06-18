

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Features/Authentication/screens/signup.dart';
import 'package:hey_you/utils/constants/text_string.dart';

import '../../../utils/constants/sizes.dart';
import 'signin.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(

        padding: TSpacingStyle.paddingWithAppBarHeight,

        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(TTexts.onBoardingTitle0, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(TTexts.onBoardingTitle1, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(TTexts.onBoardingUnder1, style: Theme.of(context).textTheme.bodyMedium),
          
              const SizedBox(height: TSizes.spaceBtwSections),
          
          
              Text(TTexts.onBoardingTitle2, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: TSizes.spaceBtwItems),
              StepCard(stepNumber: '1', title: TTexts.onBoardingCard1, description: TTexts.onBoardingUnderCard1),
              const SizedBox(height: TSizes.spaceBtwItems),
              StepCard(stepNumber: '2', title: TTexts.onBoardingCard2, description: TTexts.onBoardingUnderCard2),
              const SizedBox(height: TSizes.spaceBtwItems),
              StepCard(stepNumber: '3', title: TTexts.onBoardingCard3, description: TTexts.onBoardingUnderCard3),
              const SizedBox(height: TSizes.spaceBtwItems),
          

              /// Sign In Button
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
                final storage = GetStorage();
                storage.write('isFirstTime', false);
                Get.to(() => LoginScreen());
              }, child: const Text(TTexts.onBoardingSignIn))),
              const SizedBox(height: TSizes.spaceBtwItems),
          
              /// Sign Up Button
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {
                final storage = GetStorage();
                storage.write('isFirstTime', false);
                Get.to(() => SignUpScreen());
              }, child: const Text(TTexts.onBoardingSignUp)))
          
          
            ]
          ),
        ),
      )
    );
  }
}


class StepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color iconColor;

  const StepCard({
    Key? key,
    required this.stepNumber,
    required this.title,
    required this.description,
    this.backgroundColor = const Color(0xFFE0F0FF), // subtle blue background
    this.iconColor = const Color(0xFF6C63FF), // a clean indigo-violet
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number Circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                stepNumber,
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


