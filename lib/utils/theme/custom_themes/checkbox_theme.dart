import 'package:flutter/material.dart';

class TCheckboxTheme {
  TCheckboxTheme._();

  static CheckboxThemeData lightCheckboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    checkColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.grey.shade400;
      }
      if (states.contains(WidgetState.selected)) {
        return Colors.black;
      }
      return Colors.transparent;
    }),
    fillColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.blue;
      }
      return Colors.transparent;
    }),
  );
}