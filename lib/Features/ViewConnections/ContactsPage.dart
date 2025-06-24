import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:hey_you/Common/navigation_menu.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Features/ViewConnections/previousConnections.dart';
import 'package:hey_you/Features/Match/scheduledMeetUps.dart';
import 'package:hey_you/utils/constants/sizes.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/text_string.dart';


class ContactsPage extends StatefulWidget {

  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> with AutomaticKeepAliveClientMixin{

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final NavigationController controller = Get.find<NavigationController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: TSpacingStyle.normalPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TTexts.connectionsTitleCard,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 4),
                  Text(
                      TTexts.connectionsDescriptionCard,
                      style: Theme.of(context).textTheme.bodySmall
                  ),
                ],
              ),
            ),

            SizedBox(height: TSizes.spaceBtwSections),

            /// Previous Connections Sections
            sectionTitle(Iconsax.personalcard, TTexts.previousConnections),
            SizedBox(height: TSizes.spaceBtwItems),

            Obx(() {
              final refreshValue = controller.refreshContacts.value;
              return PreviousConnection(key: ValueKey(refreshValue));
            })


          ],
        ),
      ),

    );
  }

  Widget sectionTitle(IconData icon, String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: TColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(width: 10),
          Icon(icon, color: Colors.black),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
