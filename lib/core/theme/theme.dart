import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData saqgoTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: SaqgoColors.navy,
  colorScheme: const ColorScheme.dark(
    primary: SaqgoColors.blue,
    secondary: SaqgoColors.cyan,
    surface: SaqgoColors.surface,
    error: SaqgoColors.sos,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: SaqgoColors.navy,
    foregroundColor: SaqgoColors.text,
    elevation: 0,
  ),
  dividerColor: SaqgoColors.line,
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
);
