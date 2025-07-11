import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/EditProfile/profile_controller.dart';
import 'package:hey_you/Features/PersonalityQuiz/PersonalityQuiz.dart';
import 'package:hey_you/utils/constants/text_string.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import '../Match/BottomSheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final signOutController = Get.put(AuthenticationRepository());

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

              /// Active Search Modifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Search Filters', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton.icon(
                    icon: const Icon(Iconsax.add_circle, color: TColors.primary),

                    onPressed: () async {
                      await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent, // For rounded corners
                      builder: (context) => const ModificationFullSheet(),
                      );
                      Get.put(UserRepository());
                      UserRepository.instance.saveUserRecord(currentUser);
                      // Optionally refresh your filter lists here
                    },


                    label: const Text('New Filter', style: TextStyle(color: TColors.primary)),
                  )
                ],
              ),

              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.temporaryMods.isEmpty)
                    ListTile(
                      leading: const Icon(Iconsax.calendar, color: Colors.grey),
                      title: const Text('No Daily Filters yet'),
                      subtitle: const Text('Create one to personalize your daily matches'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.temporaryMods
                          .map((mod) => _buildChip(
                          mod, isPermanent: false, controller: controller))
                          .toList(),
                    ),

                  const SizedBox(height: TSizes.spaceBtwItems),

                  if (controller.permanentMods.isEmpty)
                    ListTile(
                      leading: const Icon(Iconsax.lock, color: Colors.grey),
                      title: const Text('No Permanent Filters yet'),
                      subtitle: const Text('Create filters that stay active'),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.permanentMods
                          .map((mod) => _buildChip(
                          mod, isPermanent: true, controller: controller))
                          .toList(),
                    ),
                ],
              )),

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

  Widget _buildChip(
      String text, {
        required bool isPermanent,
        required ProfileController controller,
      }) {
    final color = isPermanent ? Colors.deepPurpleAccent : Colors.blueAccent;
    final icon = isPermanent ? Icons.push_pin_rounded : Icons.today_rounded;
    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIcon: Icon(Icons.close, color: color, size: 18),
      onDeleted: () {
        controller.deleteModification(
          description: text,
          permanent: isPermanent,
        );
      },
      backgroundColor: color.withOpacity(0.1),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withOpacity(0.22)),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }

}
