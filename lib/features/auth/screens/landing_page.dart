import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import 'widgets/social_media_button.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late VideoPlayerController _videoPlayerController;
  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.asset('assets/intro.mp4');
    try {
      await _videoPlayerController.initialize();
      _videoPlayerController.setLooping(true);
      _videoPlayerController.play();
    } catch (error) {
      if (kDebugMode) {
        print('Video Initialization Error: $error');
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  final List<String> iconsUrl = <String>[
    'assets/social_icons/apple.png',
    'assets/social_icons/instagram.png',
    'assets/social_icons/google.png',
    'assets/social_icons/email.png',
  ];

  final List<String> titles = <String>['Apple', 'Instagram', 'Google', 'Email'];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            // Video Player widget as the background
            _videoPlayerController.value.isInitialized
                ? SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: VideoPlayer(_videoPlayerController),
                )
                : Container(),
            // Add other widgets on top of the video background
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.8),
                    Color.fromRGBO(0, 0, 0, 0.6),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 58.0),
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 35.0,
                          width: 80.0,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30.0),
                    Text(
                      "Host. Join. \nMeet.",
                      style: GoogleFonts.averiaSerifLibre(
                        color: Colors.white,
                        fontSize: 42.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      "Book your table, rock the vibe, and leave the FOMO behind!",
                      style: GoogleFonts.basic(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    SocialMediaButton(
                      onTap: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                      iconUrl: iconsUrl[3],
                      title: 'Sign in with ${titles[3]}',
                    ),
                    // Column(
                    //   children: Platform.isIOS
                    //       ? List.generate(
                    //           4,
                    //           (index) => SocialMediaButton(
                    //             onTap: () async {
                    //               if (index == 0) {
                    //                 await _authController.signInWithApple();
                    //               }
                    //               if (index == 1) {
                    //                 print('Instagram Sign In Placeholder');
                    //               }
                    //               if (index == 2) {
                    //                 await _authController.signInWithGoogle();
                    //               }
                    //               if (index == 3) {
                    //                 Get.to(() =>
                    //                     const EmailSignInScreen()); // Navigate to Email Sign In Screen
                    //               }
                    //             },
                    //             iconUrl: iconsUrl[index],
                    //             title: 'Sign in with ${titles[index]}',
                    //           ),
                    //         )
                    //       : List.generate(
                    //           3,
                    //           (index) => SocialMediaButton(
                    //             onTap: () async {
                    //               if (index == 0) {
                    //                 print('Instagram Sign In Placeholder');
                    //               }
                    //               if (index == 1) {
                    //                 await _authController.signInWithGoogle();
                    //               }
                    //               if (index == 2) {
                    //                 Get.toNamed(
                    //                     '/email-signin'); // Navigate to Email Sign In Screen
                    //               }
                    //             },
                    //             iconUrl: iconsUrl[index + 1],
                    //             title: 'Sign in with ${titles[index + 1]}',
                    //           ),
                    //         ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top: 44.0),
                      child: Center(
                        child: Text(
                          'By continuing, you accept our',
                          style: GoogleFonts.basic(
                            fontSize: 16.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 38.0),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Terms & conditions & privacy policy',
                            style: GoogleFonts.basic(
                              fontSize: 16.0,
                              color: const Color.fromRGBO(112, 147, 237, 1.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
