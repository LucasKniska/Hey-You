import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/Authentication/controllers/forgotPassword_controller.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../Common/styles/spacing_styles.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/text_string.dart';
import 'signin.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());

    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: IntrinsicHeight(
            child: Padding(
              padding: TSpacingStyle.normalPadding,
              child: Stack(
                children: [
                  /// Back Button
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Iconsax.arrow_left_3),
                        onPressed: () => Get.offAll(() => const LoginScreen()),
                      ),
                    ),
                  ),

                  /// Main Column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Center(
                        child: Column(
                          children: [
                            Text(
                              TTexts.forgotPassword,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: TSizes.sm),
                            Text(
                              TTexts.forgotPasswordSubtext,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      /// Form
                      Form(
                        key: controller.forgotPasswordFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: controller.email,
                              validator: (value) => controller.validateEmail(value),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Iconsax.direct_right),
                                labelText: TTexts.email,
                              ),
                            ),

                            const SizedBox(height: TSizes.spaceBtwInputFields),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => controller.sendResetEmail(),
                                child: const Text(TTexts.sendResetEmail),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      /// Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(TTexts.rememberPassword,
                              style: Theme.of(context).textTheme.bodyMedium),
                          GestureDetector(
                            onTap: () => Get.offAll(() => const LoginScreen()),
                            child: Text(
                              TTexts.login,
                              style: TextStyle(color: TColors.primary),
                            ),
                          ),
                        ],
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
