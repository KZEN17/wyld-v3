import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../../auth/screens/widgets/section_title.dart';

class InviteSuccess extends StatefulWidget {
  const InviteSuccess({super.key});

  @override
  State<InviteSuccess> createState() => _InviteSuccessState();
}

class _InviteSuccessState extends State<InviteSuccess> {
  late ConfettiController _controllerCenter;
  bool loading = true;

  @override
  void initState() {
    _controllerCenter = ConfettiController(
      duration: const Duration(seconds: 10),
    );
    _controllerCenter.play();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    Widget mainBody = Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _controllerCenter,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: true,
            emissionFrequency: 0.005,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [Colors.green, Colors.white, Colors.teal],
            createParticlePath: drawStar,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Image.asset('assets/gif/glasses.gif'),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            children: [
              const Spacer(),
              const SectionTitle(title: 'Congratulations', fontSize: 36.0),
              const SizedBox(height: 20.0),
              const Text(
                'Your event will be shared with \nthe community',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FullWidthButton(
                  icon: const Icon(Icons.done),
                  name: 'Done',
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 15.0,
                ),
                child: Container(
                  height: 56.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40.0),
                    color: AppColors.primaryWhite,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                    ),
                    onPressed: () {
                      // Share functionality would go here
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.share, color: AppColors.primaryBackground),
                        SizedBox(width: 10.0),
                        Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 20.0,
                            color: AppColors.primaryBackground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body:
          loading
              ? Center(child: Image.asset('assets/gif/glasses.gif'))
              : mainBody,
    );
  }
}
