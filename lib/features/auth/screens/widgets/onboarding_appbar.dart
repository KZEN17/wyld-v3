import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class OnboardingAppbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showLeading;
  final Function()? onTapBack;
  const OnboardingAppbar({super.key, this.showLeading = true, this.onTapBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryBackground,
      automaticallyImplyLeading: false,
      flexibleSpace: Center(
        child: Image.asset('assets/logo.png', height: 27.0, width: 146.0),
      ),
      leading:
          showLeading
              ? Center(
                child: GestureDetector(
                  onTap: () {
                    onTapBack?.call();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    height: 32.0,
                    width: 32.0,
                    child: Image.asset('assets/close.png'),
                  ),
                ),
              )
              : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
