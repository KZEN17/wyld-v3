import 'package:flutter/material.dart';

class GradientDivider extends StatelessWidget {
  final double height;
  final Gradient gradient;
  final double thickness;

  const GradientDivider({
    super.key,
    this.height = 1.0,
    required this.gradient,
    this.thickness = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
      ),
    );
  }
}
