import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final double fontSize;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  const SectionTitle(
      {super.key,
      required this.title,
      this.fontSize = 32.0,
      this.fontWeight = FontWeight.w600,
      this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        textAlign: textAlign,
        style: GoogleFonts.basic(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    );
  }
}
