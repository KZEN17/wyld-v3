import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class BottomText extends StatelessWidget {
  final String text;
  const BottomText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.primaryWhite, fontSize: 12.0),
      ),
    );
  }
}
