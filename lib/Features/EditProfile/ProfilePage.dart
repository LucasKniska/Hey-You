import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/EditProfile/profile_controller.dart';
import 'package:hey_you/Features/PersonalityQuiz/PersonalityQuiz.dart';
import 'package:hey_you/utils/constants/text_string.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final currentUser = UserRepository.instance.currentUser;
  final controller = Get.put(ProfileController());
  final signOutController = Get.put(AuthenticationRepository());


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: TSpacingStyle.normalPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Profile Header
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Iconsax.profile_tick)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currentUser.firstName} ${currentUser.lastName[0]}.',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.totalConnections != 1
                                ? '${currentUser.totalConnections} Connections'
                                : '1 Connection',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              /// Biography
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Public Bio', style: Theme.of(context).textTheme.titleMedium),
                          Obx(() => TextButton.icon(
                            icon: Icon(
                              controller.editBiography.value
                                  ? Iconsax.save_add
                                  : Iconsax.edit_2,
                              size: TSizes.iconMd,
                              color: TColors.primary,
                            ),
                            onPressed: () {
                              controller.editBiography.value =
                              !controller.editBiography.value;
                              controller.saveBiography();
                            },
                            label: Text(
                              controller.editBiography.value ? 'Save' : 'Edit',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: TColors.primary),
                            ),
                          ))
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(
                            () => TextField(
                          maxLines: 3,
                          maxLength: 128,
                          controller: controller.biography,
                          readOnly: !controller.editBiography.value,
                          decoration: const InputDecoration(
                            hintText: TTexts.publicBioHint,
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),


              /// Personality Quiz Update
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Iconsax.document_text, color: TColors.primary),
                  title: const Text('Personality Quiz'),
                  subtitle: const Text('You can update your answers anytime'),
                  trailing: TextButton(
                    onPressed: () => Get.to(PersonalityQuizPage()),
                    child: const Text('Update'),
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Iconsax.logout, color: Color(0xFFD32F2F)), // a professional red
                  label: const Text(
                    "Sign Out",
                    style: TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Sign Out', style: TextStyle(color: Color(0xFFD32F2F))),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      signOutController.signOut();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    backgroundColor: Colors.transparent,
                    minimumSize: const Size(150, 48),
                  ),
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}
