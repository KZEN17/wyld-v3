import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class FullWidthButton extends StatelessWidget {
  final Widget? icon;
  final String name;
  final double fontSize;
  final Function() onPressed;
  final EdgeInsets edgeInsets;
  final LinearGradient? gradient;
  final BoxBorder? border;
  const FullWidthButton({
    super.key,
    this.icon,
    required this.name,
    required this.onPressed,
    this.fontSize = 20.0,
    this.edgeInsets = const EdgeInsets.all(24.0),
    this.gradient = AppColors.mainGradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: edgeInsets,
      child: Container(
        height: 56.0,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40.0),
          gradient: gradient,
          border: border,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent, // Set the primary color to transparent
            elevation: 0, // Remove the default shadow
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon != null ? icon! : const SizedBox(),
              const SizedBox(width: 10.0),
              Text(
                name,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
