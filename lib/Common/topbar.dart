

import 'package:flutter/material.dart';

import '../utils/constants/colors.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {

  final bool backArrow;

  const TopBar({super.key, this.backArrow=false});



  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: backArrow
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,// hides back arrow
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
            colors: [TColors.primary, TColors.accent, TColors.accent, TColors.primary], // you can change these!
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
