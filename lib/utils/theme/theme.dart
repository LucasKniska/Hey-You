import 'package:flutter/material.dart';
import 'package:hey_you/utils/theme/custom_themes/appbar_theme.dart';
import 'package:hey_you/utils/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:hey_you/utils/theme/custom_themes/checkbox_theme.dart';
import 'package:hey_you/utils/theme/custom_themes/chip_theme.dart';
import 'package:hey_you/utils/theme/custom_themes/elevated_button_theme.dart';
import 'package:hey_you/utils/theme/custom_themes/light_outlined_button_theme.dart';
import 'package:hey_you/utils/theme/custom_themes/text_field_theme.dart';
import 'package:hey_you/utils/theme/custom_themes/text_theme.dart';


class TAppTheme {
  TAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Font Family
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: TTextTheme.lightTextTheme,
    chipTheme: TChipTheme.lightChipTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,

  );

  static ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      // Font Family
      brightness: Brightness.dark,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      textTheme: TTextTheme.darkTextTheme
  );
}