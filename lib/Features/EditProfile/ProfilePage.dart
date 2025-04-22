import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Common/topbar.dart';
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
  @override
  Widget build(BuildContext context) {

    final controller = Get.put(ProfileController());

    return Scaffold(
      appBar: TopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: TSpacingStyle.normalPadding,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              /// Profile section
              Container(
                decoration: BoxDecoration(
                  color: TColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),

                padding: TSpacingStyle.normalPadding/2,

                child: Row(
                  children: [
                    const Icon(Iconsax.profile_tick, size: 30),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentUser.firstName} ${currentUser.lastName[0]}.',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${currentUser.totalConnections} Connections',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: TSizes.spaceBtwItems),

              /// Biography
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Public Biography', style: Theme.of(context).textTheme.headlineSmall),
                  Obx(
                      () => TextButton.icon(
                        icon: Icon(controller.editBiography.value ? Iconsax.save_add : Iconsax.edit_2, size: TSizes.iconMd, color: TColors.primary),
                        onPressed: () { controller.editBiography.value = !controller.editBiography.value; controller.saveBiography(); },
                        label: Text(controller.editBiography.value ? 'Save' : 'Edit', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: TColors.primary)),
                    ),
                  ),
                ],
              ),
              Obx(
                () => TextField(
                  maxLines: 3,
                  maxLength: 128,
                  controller: controller.biography,
                  readOnly: !controller.editBiography.value,
                  decoration: InputDecoration(
                    hintText: TTexts.publicBioHint,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

                  ),
                ),
              ),

              SizedBox(height: TSizes.spaceBtwSections),

              /// Active Search Modifications
              Text('Active Search Modifications', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: TSizes.spaceBtwItems),



              Text((currentUser.temporaryModifications.isEmpty) ? 'Create New Daily Modifications in Map View' : 'Daily Modifications', style: Theme.of(context).textTheme.bodyLarge),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentUser.temporaryModifications.map((e) => _buildChip(e['modification'].toString(), isPermanent: false, controller: controller)).toList()
              ),


              SizedBox(height: TSizes.spaceBtwItems),

              Text((currentUser.permanentModifications.isEmpty) ? 'Create New Permanent Modifications in Map View' : 'Permanent Modifications', style: Theme.of(context).textTheme.bodyLarge),


              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentUser.permanentModifications.map((e) => _buildChip(e, isPermanent: true, controller: controller)).toList()
              ),

              const SizedBox(height: 24),

              /// Quiz Answers Section
              Wrap(
                children: [
                  Text('Retake Personality Quiz?', style: Theme.of(context).textTheme.headlineSmall),

                  TextButton.icon(
                    icon: Icon(Iconsax.refresh, size: TSizes.iconMd, color: TColors.primary),
                    onPressed: () { Get.to(PersonalityQuizPage()); },
                    label: Text('Update Answers', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: TColors.primary)),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String text, {required bool isPermanent, required ProfileController controller}) {
    return Chip(
      label: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      // deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
      // onDeleted: () { controller.obsForChips.value = !controller.obsForChips.value; controller.deleteModification(description: text, permanent: isPermanent); },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

}
