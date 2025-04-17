import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
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
        return _buildProfileUI(context, user);
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

  Widget _buildProfileUI(BuildContext context, UserModel user) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: ListView(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          children: [
            _buildCoverPhoto(context, user),
            _buildProfileHeader(user),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40.0),
                  _buildBioSection(user),
                  const Divider(
                    color: AppColors.secondaryBackground,
                    thickness: 1.0,
                  ),
                  const SizedBox(height: 40.0),
                  _buildPhotosSection(user),
                  const Divider(
                    color: AppColors.secondaryBackground,
                    thickness: 1.0,
                  ),
                  const SizedBox(height: 40.0),
                  _buildHostedSection(),
                  const Divider(
                    color: AppColors.secondaryBackground,
                    thickness: 1.0,
                  ),
                  const SizedBox(height: 40.0),
                  _buildJoinedSection(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPhoto(BuildContext context, UserModel user) {
    return Container(
      color: AppColors.errorRed,
      height: MediaQuery.of(context).size.height * 0.2,
      child:
          user.coverPhoto.isEmpty
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            height: 30.0,
                            width: 30.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBackground,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Icon(
                                Icons.arrow_back_ios,
                                size: 20.0,
                                color: AppColors.primaryWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Upload cover image functionality would go here
                    },
                    child: Center(
                      child: Container(
                        width: 180.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          border: Border.all(color: AppColors.primaryWhite),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: AppColors.primaryWhite),
                              Text(
                                'Add Cover image',
                                style: TextStyle(
                                  color: AppColors.primaryWhite,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            height: 10.0,
                            width: 10.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(user.coverPhoto),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 30.0,
                              width: 30.0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryBackground,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 20.0,
                                  color: AppColors.primaryWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    final hasProfileImage = user.profileImages.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      leading: CircleAvatar(
        radius: 50.0,
        backgroundColor: AppColors.secondaryBackground,
        backgroundImage:
            hasProfileImage ? NetworkImage(user.profileImages[0]) : null,
        child:
            !hasProfileImage
                ? const Icon(Icons.person, color: AppColors.primaryWhite)
                : null,
      ),
      trailing: SizedBox(
        height: 50.0,
        width: 50.0,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/profile-settings');
          },
          child: const Icon(
            Icons.settings_outlined,
            color: AppColors.secondaryWhite,
            size: 25.0,
          ),
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          color: AppColors.primaryWhite,
          fontSize: 28.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Padding(
        padding: EdgeInsets.only(top: 5.0),
        child: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primaryWhite),
            SizedBox(width: 10.0),
            Text(
              'Nashville, Tx',
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 16.0,
                fontWeight: FontWeight.w200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bio',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            user.bio.isNotEmpty ? user.bio : 'No bio added yet.',
            style: const TextStyle(
              fontSize: 18.0,
              color: AppColors.secondaryWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'Photos',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        user.userImages.isNotEmpty
            ? GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: user.userImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(user.userImages[index]),
                    ),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                );
              },
            )
            : const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'No photos added yet.',
                style: TextStyle(
                  color: AppColors.secondaryWhite,
                  fontSize: 18.0,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildHostedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'Hosted',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'No Tables hosted yet.',
            style: TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'Joined',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 91.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: EventWidget(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EventWidget extends StatelessWidget {
  const EventWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 91.0,
      width: 305.0,
      decoration: BoxDecoration(
        color: AppColors.grayBorder,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 91.0,
                width: 94.0,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    topLeft: Radius.circular(12.0),
                  ),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/sample_table1.png'),
                  ),
                ),
              ),
              Positioned(
                child: Container(
                  height: 50.0,
                  width: 49.0,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryWhite,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '8',
                        style: TextStyle(
                          color: AppColors.primaryPink,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Guests',
                        style: TextStyle(
                          color: AppColors.grayBorder,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lake\'s Private Sale',
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.0,
                      color: AppColors.secondaryWhite,
                    ),
                    SizedBox(width: 5.0),
                    Text(
                      'McGettigans',
                      style: TextStyle(
                        color: AppColors.secondaryWhite,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Text(
                  '14 Jan, 11:30 am',
                  style: TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 50.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Text(
                    'Ended',
                    style: TextStyle(
                      color: Color.fromRGBO(255, 0, 15, 1.0),
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
