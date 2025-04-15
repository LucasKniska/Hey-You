

import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget{

  @override
  final Size preferredSize;  // You must define preferredSize, this defines the height of the AppBar.

  TopBar({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight), // Set the height of the AppBar
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue[900], // Navy Blue color
      title: Text(
        'Hey You',
        style: TextStyle(
          fontWeight: FontWeight.bold, // Make the text bold
          fontSize: 24,
          color: Colors.white,// Optional: Adjust the font size
        ),
      ),
      centerTitle: true, // Ensures that the title is centered
    );
  }

}