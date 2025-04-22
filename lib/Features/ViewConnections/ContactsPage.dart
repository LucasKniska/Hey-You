import 'package:flutter/material.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Features/ViewConnections/previousConnections.dart';
import 'package:hey_you/Features/ViewConnections/scheduledMeetUps.dart';
import 'package:hey_you/utils/constants/sizes.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/text_string.dart';




class ContactsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopBar(),
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

            /// Scheduled Meet Ups Section
            sectionTitle(Iconsax.clock, TTexts.scheduledMeetUps),
            SizedBox(height: TSizes.spaceBtwItems),

            ScheduledConnections(),



            /// Previous Connections Sections
            sectionTitle(Iconsax.personalcard, TTexts.previousConnections),
            SizedBox(height: TSizes.spaceBtwItems),

            PreviousConnection(),


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

}
