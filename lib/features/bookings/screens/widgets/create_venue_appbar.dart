import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CreateTabAppbar extends StatelessWidget implements PreferredSizeWidget {
  final Function()? onTap;
  const CreateTabAppbar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            height: 32.0,
            width: 32.0,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 18.0,
                    color: AppColors.primaryBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Center(
          child: GestureDetector(
            onTap: () {
              onTap!();
              Navigator.of(context).pushNamed('/home');
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              height: 32.0,
              width: 32.0,
              child: const Icon(
                Icons.close,
                color: AppColors.primaryBackground,
                size: 18.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15.0),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
