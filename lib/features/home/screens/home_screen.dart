import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/create/screens/create_event_screen.dart';
import '../../bookings/screens/bookings_screen.dart';
import '../../chat/screens/main_chat_screen.dart';
import '../../explore/screens/explore_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ExploreScreen(),
    BookingsScreen(),
    CreateEventScreen(),
    MainChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      appBar: _buildAppBar(context, authState),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar(BuildContext context, AsyncValue<dynamic> authState) {
    return AppBar(
      toolbarHeight: 70.0,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primaryBackground,
      centerTitle: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Image.asset('assets/logo.png', height: 35.0, width: 80.0),
      ),
      actions: [
        SvgPicture.asset('assets/svg/location.svg', height: 30.0, width: 30.0),
        Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: SizedBox(
            height: 30.0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: badges.Badge(
                  badgeStyle: const badges.BadgeStyle(
                    badgeGradient: badges.BadgeGradient.linear(
                      colors: [
                        Color.fromRGBO(208, 54, 150, 1.0),
                        Color.fromRGBO(215, 59, 84, 1.0),
                      ],
                    ),
                  ),
                  position: badges.BadgePosition.topStart(),
                  badgeContent: const Text('7'),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.primaryWhite,
                    size: 30.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        authState.when(
          data: (user) {
            if (user != null && user.profileImages.isNotEmpty) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/profile-view');
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: badges.Badge(
                      badgeStyle: const badges.BadgeStyle(
                        badgeGradient: badges.BadgeGradient.linear(
                          colors: [
                            Color.fromRGBO(208, 54, 150, 1.0),
                            Color.fromRGBO(215, 59, 84, 1.0),
                          ],
                        ),
                      ),
                      position: badges.BadgePosition.topStart(),
                      badgeContent: const Text('4'),
                      child: Container(
                        height: 36.0,
                        width: 36.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.grayBorder,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(user.profileImages[0]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else if (user != null && user.userImages.isNotEmpty) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/profile-view');
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: badges.Badge(
                      badgeStyle: const badges.BadgeStyle(
                        badgeGradient: badges.BadgeGradient.linear(
                          colors: [
                            Color.fromRGBO(208, 54, 150, 1.0),
                            Color.fromRGBO(215, 59, 84, 1.0),
                          ],
                        ),
                      ),
                      position: badges.BadgePosition.topStart(),
                      badgeContent: const Text('4'),
                      child: Container(
                        height: 36.0,
                        width: 36.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.grayBorder,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(user.userImages[0]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/profile-view');
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: badges.Badge(
                      badgeStyle: const badges.BadgeStyle(
                        badgeGradient: badges.BadgeGradient.linear(
                          colors: [
                            Color.fromRGBO(208, 54, 150, 1.0),
                            Color.fromRGBO(215, 59, 84, 1.0),
                          ],
                        ),
                      ),
                      position: badges.BadgePosition.topStart(),
                      badgeContent: const Text('4'),
                      child: Container(
                        height: 36.0,
                        width: 36.0,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.grayBorder,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryWhite,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (_, __) => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: AppColors.secondaryBackground,
      selectedItemColor: AppColors.primaryPink,
      unselectedItemColor: AppColors.secondaryWhite,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      type: BottomNavigationBarType.fixed,
      items: [
        _buildBottomNavItem(0, 'Explore', 'assets/svg/explore.svg'),
        _buildBottomNavItem(
          1,
          'Bookings',
          'assets/navigation/bookings.png',
          isSvg: false,
        ),
        _buildBottomNavItem(
          2,
          'Create',
          'assets/navigation/create.png',
          isSvg: false,
        ),
        _buildBottomNavItem(
          3,
          'Chat',
          'assets/navigation/chat.png',
          isSvg: false,
        ),
      ],
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    int index,
    String label,
    String assetPath, {
    bool isSvg = true,
  }) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 45.0,
        child: Column(
          children: [
            _selectedIndex != index
                ? const SizedBox()
                : Container(
                  height: 6.0,
                  width: 50.0,
                  decoration: const BoxDecoration(
                    gradient: AppColors.mainGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                  ),
                ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child:
                  isSvg
                      ? SvgPicture.asset(
                        assetPath,
                        colorFilter:
                            _selectedIndex != index
                                ? ColorFilter.mode(
                                  AppColors.secondaryWhite,
                                  BlendMode.srcIn,
                                )
                                : ColorFilter.mode(
                                  AppColors.primaryPink,
                                  BlendMode.srcIn,
                                ),
                      )
                      : Image.asset(
                        assetPath,
                        color:
                            _selectedIndex != index
                                ? AppColors.secondaryWhite
                                : AppColors.primaryPink,
                      ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
