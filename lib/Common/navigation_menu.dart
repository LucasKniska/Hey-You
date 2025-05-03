

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/utils/constants/sizes.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../Features/EditProfile/ProfilePage.dart';
import '../Features/Match/MapPage.dart';
import '../Features/ViewConnections/ContactsPage.dart';
import '../utils/constants/colors.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {

    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
          () => NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              elevation: 8,
              indicatorColor: TColors.accent,
              labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                  (states) => TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: states.contains(MaterialState.selected)
                      ? Colors.blue.shade700
                      : Colors.grey.shade600,
                ),
              ),
              iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
                    (states) => IconThemeData(
                  color: states.contains(MaterialState.selected)
                      ? Colors.blue.shade700
                      : Colors.grey.shade500,
                ),
              ),
            ),
            child: NavigationBar(

              height: TSizes.appBarHeight,
              elevation: 0,
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: (index) => controller.selectedIndex.value = index,
              destinations: [
                NavigationDestination(icon: Icon(Iconsax.people), label: 'Contacts'),
                NavigationDestination(icon: Icon(Iconsax.map), label: 'Map'),
                NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
              ]
            ),
          ),
      ),

      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController{
  final Rx<int> selectedIndex = 0.obs;

  final screens = [ContactsPage(), MapPage(), ProfilePage()];
}
