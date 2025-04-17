import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/features/auth/controllers/onboarding_controller.dart';
import 'package:wyld/features/auth/screens/widgets/onboarding_appbar.dart';
import 'package:wyld/shared/widgets/full_width_button.dart';

class PhotosStep extends ConsumerStatefulWidget {
  final Function onNext;

  const PhotosStep({super.key, required this.onNext});

  @override
  ConsumerState<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends ConsumerState<PhotosStep> {
  final picker = ImagePicker();
  bool isLoading = false;
  int currentImageIndex = 0;
  int totalImages = 0;
  String isLoadingText = 'Loading...';

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      ref.read(onboardingControllerProvider.notifier).addPhotos([imageFile]);
    }
  }

  Future<void> getImages() async {
    final pickedFile = await picker.pickMultiImage(
      imageQuality: 100,
      maxHeight: 1000,
      maxWidth: 1000,
    );
    List<XFile> xfilePick = pickedFile;

    if (xfilePick.isNotEmpty) {
      final imageFiles = xfilePick.map((xFile) => File(xFile.path)).toList();
      ref.read(onboardingControllerProvider.notifier).addPhotos(imageFiles);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nothing is selected')));
      }
    }
  }

  void _removeImage(int index) {
    ref.read(onboardingControllerProvider.notifier).removePhoto(index);
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryWhite,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        getImages();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: AppColors.primaryWhite, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final selectedImages = onboardingState.photos;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const OnboardingAppbar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add your \nphotos',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primaryWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedImages.isNotEmpty)
                            TextButton(
                              onPressed: _showImageSourceBottomSheet,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 15.0,
                                    color: AppColors.primaryPink,
                                  ),
                                  Text(
                                    '  ADD MORE',
                                    style: TextStyle(
                                      color: AppColors.primaryPink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // Instagram integration would go here
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Container(
                            height: 100.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromRGBO(255, 154, 74, 1.0),
                                  Color.fromRGBO(201, 56, 172, 1.0),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primaryWhite,
                                  size: 30,
                                ),
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Instagram",
                                      style: TextStyle(
                                        color: AppColors.primaryWhite,
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "Connect",
                                      style: TextStyle(
                                        color: AppColors.primaryWhite,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: const Divider(
                                thickness: 2.0,
                                color: AppColors.secondaryWhite,
                              ),
                            ),
                            const Text(
                              'or',
                              style: TextStyle(color: AppColors.primaryWhite),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.4,
                              child: const Divider(
                                thickness: 2.0,
                                color: AppColors.secondaryWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child:
                            !isLoading
                                ? GridView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        childAspectRatio: 150.0 / 105.0,
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 20.0,
                                        crossAxisSpacing: 40.0,
                                      ),
                                  children:
                                      selectedImages.isEmpty
                                          ? List.generate(
                                            4,
                                            (index) => GestureDetector(
                                              onTap:
                                                  _showImageSourceBottomSheet,
                                              child: Container(
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.15,
                                                width: 150.0,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors
                                                          .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.0,
                                                      ),
                                                ),
                                                child: const Icon(
                                                  CupertinoIcons.add,
                                                  size: 20.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                          : List.generate(
                                            selectedImages.length,
                                            (index) {
                                              return Stack(
                                                children: [
                                                  Container(
                                                    height:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.height *
                                                        0.3,
                                                    width: 167.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10.0,
                                                          ),
                                                      image: DecorationImage(
                                                        fit: BoxFit.cover,
                                                        image: FileImage(
                                                          selectedImages[index],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 5,
                                                    right: 5,
                                                    child: GestureDetector(
                                                      onTap:
                                                          () => _removeImage(
                                                            index,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Colors.red,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                )
                                : Center(
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryPink,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Uploading image \n$currentImageIndex/$totalImages',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.primaryWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            selectedImages.isNotEmpty && !isLoading
                ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FullWidthButton(
                    name: 'Next',
                    icon: const Icon(
                      CupertinoIcons.chevron_forward,
                      color: Colors.white,
                      size: 18.0,
                    ),
                    onPressed: () => widget.onNext(),
                  ),
                )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
