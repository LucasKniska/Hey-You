import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Features/Authentication/controllers/signin_controller.dart';
import 'package:hey_you/Features/Authentication/screens/forgotPassword.dart';
import 'package:hey_you/Features/Authentication/screens/signup.dart';
import 'package:hey_you/utils/constants/text_string.dart';
import 'package:hey_you/utils/validators/validation.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../Common/styles/spacing_styles.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import 'onboarding.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final controller = Get.put(SignInController());

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
                            transition: Transition.leftToRight, // This slides the new page in from the right
                            duration: Duration(milliseconds: 400), // Optional: controls animation speed
                          );
                        },
                      ),
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Center(
                        child: Column(
                          children: [
                            Text(
                              TTexts.loginTitle1,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: TSizes.sm),
                            Text(
                              TTexts.loginUnder1,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      /// Form
                      Form(
                        key: controller.signinFormKey,
                        child: Column(
                          children: [


                            /// Email Field
                            TextFormField(
                              key: GlobalKey<FormState>(),
                              validator: (value) => TValidator.validateEmail(value),
                              controller: controller.email,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Iconsax.direct_right),
                                labelText: TTexts.email,
                              ),
                            ),
                            const SizedBox(height: TSizes.spaceBtwInputFields),
                            /// Password Field
                            Obx(
                                () => TextFormField(
                                  key: GlobalKey<FormState>(),
                                validator: (value) => TValidator.validatePassword(value),
                                controller: controller.password,
                                obscureText: controller.hidePassword.value,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Iconsax.password_check),
                                  labelText: TTexts.password,
                                  suffixIcon: IconButton(
                                    icon: controller.hidePassword.value ? Icon(Iconsax.eye) : Icon(Iconsax.eye_slash),
                                    onPressed: () { controller.hidePassword.value = !controller.hidePassword.value; }
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: TSizes.spaceBtwInputFields / 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Obx(() => Checkbox(value: controller.rememberMe.value, onChanged: (value) { controller.rememberMe.value = value!; })),
                                Text(
                                  TTexts.rememberMe,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    Get.to(() => ForgotPasswordScreen());
                                  },
                                  child: Text(
                                    TTexts.forgotPassword,
                                    style: TextStyle(color: TColors.primary),
                                  ),
                                ),
                              ],
                            ),

                            /// Sign In Button
                            const SizedBox(height: TSizes.spaceBtwItems),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () { controller.signin(); },
                                child: const Text(TTexts.login),
                              ),
                            ),
                            const SizedBox(height: TSizes.spaceBtwItems),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  TTexts.noAccount,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: () { Get.offAll(() => SignUpScreen());},
                                  child: Text(
                                    TTexts.signUp,
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
