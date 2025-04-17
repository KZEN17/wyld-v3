import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/widgets/section_title.dart';

class ProfileSettings extends ConsumerStatefulWidget {
  const ProfileSettings({super.key});

  @override
  ConsumerState<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends ConsumerState<ProfileSettings> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not authenticated')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 24.0),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.primaryWhite,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 20.0),
                          child: Container(
                            height: 80.0,
                            width: 80.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.grayBorder,
                              image:
                                  user.profileImages.isNotEmpty
                                      ? DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                          user.profileImages[0],
                                        ),
                                      )
                                      : user.userImages.isNotEmpty
                                      ? DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(user.userImages[0]),
                                      )
                                      : null,
                            ),
                            child:
                                (user.profileImages.isEmpty &&
                                        user.userImages.isEmpty)
                                    ? const Icon(
                                      Icons.person,
                                      color: AppColors.primaryWhite,
                                      size: 40,
                                    )
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: AppColors.primaryWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 24.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileSocialButton(
                    imgUrl: 'assets/svg/bookings.png',
                    color: const Color(0xFF45FFB2),
                    onTap: () {},
                  ),
                  _buildProfileSocialButton(
                    imgUrl: 'assets/svg/wallet.png',
                    color: const Color(0xFF99A3FF),
                    onTap: () {},
                  ),
                  _buildProfileSocialButton(
                    imgUrl: 'assets/svg/wishlist.png',
                    color: const Color(0xFFC173FF),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32.0),
              const Divider(
                thickness: 4.0,
                color: AppColors.secondaryBackground,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                child: SectionTitle(title: 'Settings', fontSize: 20.0),
              ),
              _buildSettingsButton(
                title: 'Personal Information',
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Payments & Invoices',
                icon: SvgPicture.asset('assets/svg/payments.svg'),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Dark Mode Toggle',
                icon: SvgPicture.asset('assets/svg/toggle.svg'),
                trailing: CupertinoSwitch(value: false, onChanged: (value) {}),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Security',
                icon: SvgPicture.asset('assets/svg/security.svg'),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Privacy & Sharing',
                icon: SvgPicture.asset('assets/svg/privacy.svg'),
                onTap: () {},
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                child: SectionTitle(title: 'Support', fontSize: 20.0),
              ),
              _buildSettingsButton(
                title: 'Help Center',
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Safety Issue',
                icon: SvgPicture.asset('assets/svg/secure.svg'),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Report',
                icon: SvgPicture.asset('assets/svg/headphones.svg'),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Feedback',
                icon: SvgPicture.asset('assets/svg/pen.svg'),
                onTap: () {},
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                child: SectionTitle(title: 'Legal', fontSize: 20.0),
              ),
              _buildSettingsButton(
                title: 'Terms of Service',
                icon: SvgPicture.asset('assets/svg/document_info.svg'),
                onTap: () {},
              ),
              _buildSettingsButton(
                title: 'Privacy Policy',
                icon: SvgPicture.asset('assets/svg/document_info.svg'),
                onTap: () {},
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .logout(context);
                    },
                    child: const Text(
                      'Log out',
                      style: TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 16.0,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.solid,
                        decorationColor: Colors.white,
                        decorationThickness: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stackTrace) => Scaffold(
            body: Center(child: Text('Error loading profile: $error')),
          ),
    );
  }

  Widget _buildProfileSocialButton({
    required String imgUrl,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Image.asset(imgUrl, width: 40, height: 40)),
      ),
    );
  }

  Widget _buildSettingsButton({
    required String title,
    required Widget icon,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: SizedBox(width: 24, height: 24, child: icon),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.primaryWhite, fontSize: 16.0),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.primaryWhite,
            size: 16.0,
          ),
      onTap: onTap,
    );
  }
}
