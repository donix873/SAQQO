import 'package:flutter/material.dart';
import 'colors.dart';

abstract final class SaqgoTypography {
  static const title = TextStyle(
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: SaqgoColors.text,
  );
  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SaqgoColors.text,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: SaqgoColors.muted,
  );
  static const label = TextStyle(fontSize: 12, color: SaqgoColors.muted);
}
