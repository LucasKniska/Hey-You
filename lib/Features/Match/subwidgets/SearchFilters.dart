

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../Data/repositories/user/user_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../EditProfile/profile_controller.dart';
import 'BottomSheet.dart';

Widget searchFilters(var context) {

  final controller = ProfileController.instance;
  final textTheme = Theme.of(context).textTheme;


  return Column(children: [

    /// Active Search Modifications
    Row(
      children: [
        const SizedBox(width: 6),
        Text('Search Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Spacer(),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: TColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
          icon: const Icon(Iconsax.add_circle, color: Colors.white),
          label: const Text('Edit Filters', style: TextStyle(color: Colors.white)),
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const ModificationFullSheet(),
            );
            UserRepository.instance.updateUserSearchFilters();
          },
        ),
        const SizedBox(width: 6),


      ],
    ),

    Divider(
      thickness: 2,
      color: Color(0xFFBFBFBF), // light gray
    ),

    Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.temporaryMods.isEmpty)
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              leading: const Icon(Iconsax.calendar, color: Colors.blueAccent),
              title: Text('No Daily Filters yet', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
              subtitle: const Text('Create one to personalize your daily matches'),
            ),
          )
        else
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Iconsax.calendar, color: Colors.blueAccent),
                    title: Text('Daily Filters', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: const Text('These are removed at the end of the day'),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.temporaryMods
                        .map((mod) => _buildChip(
                        mod, isPermanent: false, controller: controller))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),


        const SizedBox(height: TSizes.spaceBtwItems),

        if (controller.permanentMods.isEmpty)
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              leading: const Icon(Iconsax.lock, color: Colors.deepPurpleAccent),
              title: Text('No Permanent Filters Yet', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
              subtitle: const Text('Create filters that stay active'),
            ),
          )
        else
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Iconsax.lock_1, color: Colors.deepPurpleAccent),
                    title: Text('Permanent Filters', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: const Text('These are active until removed'),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.permanentMods
                        .map((mod) => _buildChip(
                        mod, isPermanent: true, controller: controller))
                        .toList(),
                  ),
                ],
              ),
            ),
          )

      ],
    )),

    const SizedBox(height: TSizes.spaceBtwSections)

  ]);
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
