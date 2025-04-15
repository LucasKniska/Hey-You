import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hey_you/Features/Authentication/screens/signup.dart';
import 'package:hey_you/utils/constants/text_string.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../Common/styles/spacing_styles.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import 'onboarding.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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

                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Iconsax.arrow_left_3),
                        onPressed: () {
                          Get.to(() => OnBoardingScreen());
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
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Iconsax.direct_right),
                                labelText: TTexts.email,
                              ),
                            ),
                            const SizedBox(height: TSizes.spaceBtwInputFields),
                            TextFormField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Iconsax.password_check),
                                labelText: TTexts.password,
                                suffixIcon: Icon(Iconsax.eye_slash),
                              ),
                            ),
                            const SizedBox(height: TSizes.spaceBtwInputFields / 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Checkbox(value: true, onChanged: (value) {}),
                                Text(
                                  TTexts.rememberMe,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    TTexts.forgotPassword,
                                    style: TextStyle(color: TColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: TSizes.spaceBtwItems),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
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
                                  onTap: () { Get.to(() => SignUpScreen());},
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
