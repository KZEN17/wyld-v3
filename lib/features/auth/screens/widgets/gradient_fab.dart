import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class GradientFloatingButton extends StatelessWidget {
  final Function() onPressed;
  const GradientFloatingButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.mainGradient,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        child: const Icon(Icons.arrow_forward, color: AppColors.primaryWhite),
      ),
    );
  }
}
