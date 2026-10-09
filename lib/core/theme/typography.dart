import 'package:flutter/material.dart';
import 'colors.dart';

abstract final class SaqgoTypography {
  static const title = TextStyle(
    fontFamily: "SaqgoSans",
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: SaqgoColors.text,
  );
  static const cardTitle = TextStyle(
    fontFamily: "SaqgoSans",
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SaqgoColors.text,
  );
  static const body = TextStyle(
    fontFamily: "SaqgoSans",
    fontSize: 14,
    height: 1.45,
    color: SaqgoColors.muted,
  );
  static const label = TextStyle(
    fontFamily: "SaqgoSans",
    fontSize: 12,
    color: SaqgoColors.muted,
  );
}
