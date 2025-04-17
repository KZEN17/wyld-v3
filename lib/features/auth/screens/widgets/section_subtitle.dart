import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class SectionSubtitle extends StatelessWidget {
  final String subtitle;
  final TextAlign textAlign;
  final double padding;
  final double fontSize;
  const SectionSubtitle({
    super.key,
    required this.subtitle,
    this.textAlign = TextAlign.left,
    this.padding = 46.0,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Text(
        subtitle,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryWhite,
        ),
      ),
    );
  }
}
