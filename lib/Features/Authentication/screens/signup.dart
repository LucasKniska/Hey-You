import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Features/Authentication/screens/signin.dart';
import 'package:hey_you/Features/Authentication/screens/onboarding.dart';
import 'package:hey_you/utils/constants/text_string.dart';
import 'package:hey_you/utils/validators/validation.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../Common/styles/spacing_styles.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/signup_controller.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());

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
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Iconsax.arrow_left_3),
                        onPressed: () {
                          Get.offAll(
                            () => OnboardingPage(), // Your page widget
                            transition:
                                Transition
                                    .leftToRight, // This slides the new page in from the right
                            duration: Duration(
                              milliseconds: 400,
                            ), // Optional: controls animation speed
                          );
                        },
                      ),
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // Centers vertically
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Center(
                        child: Column(
                          children: [
                            Text(
                              TTexts.createAccount,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: TSizes.sm),
                            Text(
                              TTexts.createAccountUnder,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      /// Form
                      Form(
                        key: controller.signupFormKey,
                        child: Column(
                          children: [
                            /// Email
                            TextFormField(
                              validator:
                                  (value) => TValidator.validateEmail(value),
                              controller: controller.email,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Iconsax.direct_right),
                                labelText: TTexts.email,
                              ),
                            ),
                            const SizedBox(height: TSizes.spaceBtwInputFields),

                            /// Password
                            Obx(
                              () => TextFormField(
                                validator:
                                    (value) =>
                                        TValidator.validatePassword(value),
                                controller: controller.password,
                                obscureText: controller.hidePassword.value,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Iconsax.password_check,
                                  ),
                                  labelText: TTexts.password,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.hidePassword.value
                                          ? Iconsax.eye
                                          : Iconsax.eye_slash,
                                    ),
                                    onPressed:
                                        () =>
                                            controller.hidePassword.value =
                                                !controller.hidePassword.value,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: TSizes.spaceBtwInputFields / 2,
                            ),

                            /// Terms of service box
                            /// Remember Me Box
                            Wrap(
                              runSpacing: -20,
                              children: [
                                Row(
                                  children: [
                                    Obx(
                                      () => Checkbox(
                                        value: controller.rememberMe.value,
                                        onChanged: (value) {
                                          controller.rememberMe.value = value!;
                                        },
                                      ),
                                    ),
                                    Text(
                                      TTexts.rememberMe,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),

                              ],
                            ),

                            /// Sign Up Function
                            const SizedBox(
                              height: TSizes.spaceBtwInputFields / 2,
                            ),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: () {
                                    controller.signup();
                                  },
                                  child: const Text(TTexts.signUp),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: TColors.primary
                                  )
                              ),
                            ),

                            const SizedBox(height: TSizes.spaceBtwItems/2),

                            /// Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => controller.googleSignUp(),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: TColors.primary
                                ),
                                child: const Text('Sign Up With Google'),
                              ),
                            ),

                            const SizedBox(height: TSizes.spaceBtwItems),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  TTexts.hasAccount,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Get.offAll(() => LoginScreen());
                                  },
                                  child: Text(
                                    TTexts.login,
                                    style: TextStyle(color: TColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
