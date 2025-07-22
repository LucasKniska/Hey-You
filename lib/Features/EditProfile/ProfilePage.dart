import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/EditProfile/profile_controller.dart';
import 'package:hey_you/Features/PersonalityQuiz/PersonalityQuiz.dart';
import 'package:hey_you/utils/constants/text_string.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import 'components/BackgroundGradient.dart';
import 'components/ProfileAndStats.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final currentUser = UserRepository.instance.currentUser;
  final controller = Get.put(ProfileController());
  final signOutController = Get.put(AuthenticationRepository());

  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedGradientBackground(controller: _gradientController),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        ProfileHeaderAndStats(currentUser: currentUser),

                        const SizedBox(height: TSizes.spaceBtwSections),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ----- PUBLIC BIO SECTION -----
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline, color: TColors.primary, size: TSizes.iconMd),
                                          const SizedBox(width: 7),
                                          Text('Public Bio', style: Theme.of(context).textTheme.titleLarge),
                                        ],
                                      ),
                                      Obx(() => TextButton.icon(
                                        icon: Icon(
                                          controller.editBiography.value ? Iconsax.save_add : Iconsax.edit_2,
                                          size: TSizes.iconMd,
                                          color: TColors.primary,
                                        ),
                                        onPressed: () {
                                          controller.editBiography.value = !controller.editBiography.value;
                                          controller.saveBiography();
                                        },
                                        label: Text(
                                          controller.editBiography.value ? 'Save' : 'Edit',
                                          style: TextStyle(color: TColors.primary),
                                        ),
                                        style: TextButton.styleFrom(
                                          minimumSize: Size(0, 34),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          padding: EdgeInsets.zero,
                                        ),
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                                  Obx(() => TextField(
                                    maxLines: 3,
                                    maxLength: 128,
                                    controller: controller.biography,
                                    readOnly: !controller.editBiography.value,
                                    decoration: InputDecoration(
                                      hintText: TTexts.publicBioHint,
                                      border: controller.editBiography.value ? const OutlineInputBorder() : InputBorder.none,
                                      counterText: '',
                                    ),
                                  )),
                                  const SizedBox(height: 18),

                                  // Divider between sections
                                  Divider(thickness: 1, color: Colors.grey[200]),

                                  // ----- PERSONALITY QUIZ SECTION -----
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Iconsax.document_text, color: TColors.primary, size: TSizes.iconMd),
                                    title: const Text('Personality Quiz'),
                                    subtitle: const Text('You can update your answers anytime'),
                                    trailing: TextButton(
                                      onPressed: () => Get.to(() => PersonalityQuizPage()),
                                      style: TextButton.styleFrom(foregroundColor: TColors.primary),
                                      child: const Text('Update'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),



                        const SizedBox(height: TSizes.spaceBtwSections),
                        const SizedBox(height: 24), // more space above


                            OutlinedButton.icon(
                              icon: const Icon(Iconsax.logout, color: Color(0xFFEC3B3B)),
                              label: const Text(
                                "Sign Out",
                                style: TextStyle(
                                  color: Color(0xFFEC3B3B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
                                    contentTextStyle: TextStyle(color: Colors.black.withOpacity(0.8)),
                                    title: const Text('Confirm Sign Out'),
                                    content: const Text('Are you sure you want to sign out?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                                      ),
                                      TextButton(
                                        onPressed: () => AuthenticationRepository.instance.signOut(),
                                        child: const Text('Sign Out', style: TextStyle(color: Color(0xFFEC3B3B))),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  signOutController.signOut();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFEC3B3B), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), // match card
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                minimumSize: const Size(double.infinity, 48), // full width of card
                              ),
                            ),

                            const SizedBox(height: 30), // more space below

                      ],
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
