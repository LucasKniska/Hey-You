
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hey_you/utils/constants/colors.dart';
import 'package:hey_you/utils/theme/theme.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Making a change to show the update
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'Hey You',

        themeMode: ThemeMode.system,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,

        home: const Scaffold(backgroundColor: TColors.primary, body: Center(child: CircularProgressIndicator(color: Colors.white)))

    );
  }
}