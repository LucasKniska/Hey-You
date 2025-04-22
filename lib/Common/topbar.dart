

import 'package:flutter/material.dart';

import '../utils/constants/colors.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // hides back arrow
      title: Text(
        'Hey You',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold, // Make the text bold
          color: Colors.white,// Optional: Adjust the font size
        ),

      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.primary, TColors.accent], // you can change these!
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent, // important for gradient to show
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
