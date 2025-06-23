

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/utils/constants/sizes.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../Features/EditProfile/ProfilePage.dart';
import '../Features/Match/MapPage.dart';
import '../Features/ViewConnections/ContactsPage.dart';
import '../utils/constants/colors.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  final controller = Get.put(NavigationController());

  @override
  void initState() {
    super.initState();
    controller.pageController.addListener(() {
      final newIndex = controller.pageController.page?.round();
      if (newIndex != null && newIndex != controller.selectedIndex.value) {
        controller.selectedIndex.value = newIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(),
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
            onDestinationSelected: (index) {
              controller.selectedIndex.value = index;
              controller.pageController.jumpToPage(index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Iconsax.people), label: 'Contacts'),
              NavigationDestination(icon: Icon(Iconsax.map), label: 'Map'),
              NavigationDestination(icon: Icon(Iconsax.user), label: 'Profile'),
            ],
          ),
        ),
      ),
      body:
          PageView(
            controller: controller.pageController,
            onPageChanged: (index) => controller.selectedIndex.value = index,
            children: controller.screens,
          ),


    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final PageController pageController = PageController();

  final List<Widget> screens = <Widget>[
    ContactsPage(),
    MapPage(),
    ProfilePage(),
  ];

  final RxBool refreshContacts = false.obs;

  void triggerContactsRefresh() {
    refreshContacts.value = !refreshContacts.value;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
