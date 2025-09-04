import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

Widget sectionTitle(IconData icon, String title) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Icon(icon, color: TColors.primary),
          ],
        ),
      ),
      Divider(
        thickness: 2,
        color: Color(0xFFBFBFBF), // light gray
      ),
    ],
  );
}