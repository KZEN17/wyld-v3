import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'gradient_divider.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final double step;
  const OnboardingProgressIndicator({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * step,
      child: const GradientDivider(
        height: 2.0,
        gradient: AppColors.mainGradient,
      ),
    );
  }
}
