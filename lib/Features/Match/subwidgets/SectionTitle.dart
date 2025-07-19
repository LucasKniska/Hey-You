import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

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