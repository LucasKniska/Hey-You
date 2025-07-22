import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:hey_you/Data/repositories/authentication/authentication_repository.dart';
import 'package:hey_you/Features/EditProfile/profile_controller.dart';
import 'package:hey_you/Features/PersonalityQuiz/PersonalityQuiz.dart';
import 'package:hey_you/utils/constants/text_string.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/sizes.dart';
import 'components/StatsWidgets.dart';

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
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  Widget _buildFlowingGradientBackground() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final t = _gradientController.value;
        final angle = 2 * pi * t;
        return Container(
          height: 240,
          margin: const EdgeInsets.only(top: 20, right: 8, left: 8),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(Color(0xFFD0E5FF), Color(0xFFCCE0FF), (sin(angle) + 1) / 2)!,
                Color.lerp(Color(0xFFCCE0FF), Color(0xFFE3F0FF), (cos(angle) + 1) / 2)!,
                Color.lerp(Color(0xFFE3F0FF), Color(0xFFD0E5FF), (sin(angle + pi) + 1) / 2)!,
              ],
              stops: [
                0.0,
                0.6 + 0.2 * sin(angle),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoftProfileHeaderCard() {
    final firstName = currentUser.firstName.isNotEmpty ? currentUser.firstName : "User";
    final lastInitial = currentUser.lastName.isNotEmpty ? "${currentUser.lastName[0]}." : "";
    final initials = "${firstName.isNotEmpty ? firstName[0] : ''}${currentUser.lastName.isNotEmpty ? currentUser.lastName[0] : ''}";
    return Container(
      margin: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            child: Text(
              initials.isNotEmpty ? initials : "U",
              style: const TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$firstName $lastInitial",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            _buildFlowingGradientBackground(),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildSoftProfileHeaderCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(TSizes.cardRadiusLg),
                              bottom: Radius.circular(0),
                            ),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(TSizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Public Bio', style: Theme.of(context).textTheme.titleLarge),
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
                              ],
                            ),
                          ),
                        ),
                        Card(
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(0),
                              bottom: Radius.circular(TSizes.cardRadiusLg),
                            ),
                          ),
                          color: Colors.white,
                          child: ListTile(
                            leading: const Icon(Iconsax.document_text, color: TColors.primary),
                            title: const Text('Personality Quiz'),
                            subtitle: const Text('You can update your answers anytime'),
                            trailing: TextButton(
                              onPressed: () => Get.to(() => PersonalityQuizPage()),
                              style: TextButton.styleFrom(foregroundColor: TColors.primary),
                              child: const Text('Update'),
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections),

                        StatsRow(currentUser: currentUser),

                        const SizedBox(height: TSizes.spaceBtwSections),

                        Center(
                          child: OutlinedButton.icon(
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
                                  titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
                                  contentTextStyle: TextStyle(color: Colors.black.withOpacity(0.8)),
                                  title: const Text('Confirm Sign Out'),
                                  content: const Text('Are you sure you want to sign out?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text('Cancel', style: TextStyle(color: Colors.black)),
                                    ),
                                    TextButton(
                                      onPressed: () => AuthenticationRepository.instance.signOut(),
                                      child: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF9A9A))),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                signOutController.signOut();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFEF9A9A), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                              backgroundColor: Colors.transparent,
                              minimumSize: const Size(150, 48),
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),
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
