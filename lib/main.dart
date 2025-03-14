import 'package:flutter/material.dart';
import 'MapPage.dart';
import 'Profile/ProfilePage.dart';
import 'Contacts/ContactsPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hey You',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ProfilePage(),
      routes: {
        '/contacts': (context) => ContactsPage(),
        '/map': (context) => MapPage(),
        '/profile': (context) => ProfilePage()
      }
    );
  }
}
