import 'package:flutter/material.dart';
import 'package:hey_you/Contacts/previousConnections.dart';
import 'package:hey_you/Contacts/wantsMatch.dart';
import '../bottombar.dart';
import '../topbar.dart';
import 'awaitingResponse.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPage();
}

class _ContactsPage extends State<ContactsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[

            // Vertical Spacer
            Container(height: 20),

            // People Trying to Connect
            WantsMatch(),

            // Vertical Spacer
            Container(height: 20),

            // You trying to connect with them
            AwaitingResponse(),

            // Vertical Spacer
            Container(height: 20),

            // Previous Connections
            PreviousConnection()



          ],
        ),
      ),

      bottomNavigationBar: BottomBar(),

    );
  }
}