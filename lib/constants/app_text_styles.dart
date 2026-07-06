import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Heading Font (Outfit)
  static TextStyle get heading1 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get heading3 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get heading4 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  // Body Font (Inter)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.15,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
      );

  // Specialized styles
  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      );
}
