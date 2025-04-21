import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../controllers/user_controller.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _bioController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isEditingBio = false;
  bool _isEditingName = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user's data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        _bioController.text = user.bio;
        _nameController.text = user.name;
        // Location would need to be reverse geocoded from coordinates
        _locationController.text = "Nashville, TN"; // Placeholder
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authControllerProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not authenticated')),
          );
        }
        return _buildEditProfileUI(context, user);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(child: Text('Error loading profile: $error', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildEditProfileUI(BuildContext context, UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.primaryWhite)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover photo section
                Stack(
                  children: [
                    // Cover photo
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        image: user.coverPhoto.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(user.coverPhoto),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: user.coverPhoto.isEmpty
                          ? const Center(
                        child: Text(
                          'No cover photo',
                          style: TextStyle(color: AppColors.secondaryWhite),
                        ),
                      )
                          : null,
                    ),

                    // Edit cover photo button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: () => _showImageSourceOptions(context, ImageType.cover),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Edit Cover'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBackground.withOpacity(0.7),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Profile image and name section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile image
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.secondaryBackground,
                            backgroundImage: user.profileImages.isNotEmpty
                                ? NetworkImage(user.profileImages[0])
                                : (user.userImages.isNotEmpty ? NetworkImage(user.userImages[0]) : null),
                            child: user.profileImages.isEmpty && user.userImages.isEmpty
                                ? const Icon(Icons.person, color: AppColors.primaryWhite, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showImageSourceOptions(context, ImageType.profile),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPink,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primaryBackground, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Name and email info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name with edit button
                            Row(
                              children: [
                                _isEditingName
                                    ? Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: AppColors.primaryWhite,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                )
                                    : Text(
                                  user.name,
                                  style: const TextStyle(
                                    color: AppColors.primaryWhite,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isEditingName ? Icons.check : Icons.edit,
                                    color: AppColors.primaryWhite,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    if (_isEditingName) {
                                      _saveName(context);
                                    } else {
                                      setState(() {
                                        _isEditingName = true;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: AppColors.secondaryWhite,
                                fontSize: 14,
                              ),
                            ),

                            // Location (placeholder for now)
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.secondaryWhite, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _locationController.text,
                                  style: const TextStyle(
                                    color: AppColors.secondaryWhite,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bio section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bio',
                            style: TextStyle(
                              color: AppColors.primaryWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditingBio ? Icons.check : Icons.edit,
                              color: AppColors.primaryWhite,
                              size: 20,
                            ),
                            onPressed: () {
                              if (_isEditingBio) {
                                _saveBio(context);
                              } else {
                                setState(() {
                                  _isEditingBio = true;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _isEditingBio
                          ? TextField(
                        controller: _bioController,
                        style: const TextStyle(color: AppColors.primaryWhite),
                        decoration: InputDecoration(
                          hintText: 'Write something about yourself...',
                          hintStyle: const TextStyle(color: AppColors.secondaryWhite),
                          filled: true,
                          fillColor: AppColors.secondaryBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        maxLines: 5,
                      )
                          : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.bio.isEmpty ? 'No bio added yet.' : user.bio,
                          style: TextStyle(
                            color: user.bio.isEmpty
                                ? AppColors.secondaryWhite
                                : AppColors.primaryWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Photos section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Photos',
                            style: TextStyle(
                              color: AppColors.primaryWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _addPhotos(context),
                            icon: const Icon(Icons.add_photo_alternate, size: 16),
                            label: const Text('Add Photos'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      user.userImages.isEmpty
                          ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.grayBorder, width: 1),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.secondaryWhite,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No photos added yet',
                              style: TextStyle(color: AppColors.secondaryWhite),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _addPhotos(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPink,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add Photos'),
                            ),
                          ],
                        ),
                      )
                          : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: user.userImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(context, user.userImages[index]),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    user.userImages[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppColors.secondaryBackground,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.secondaryBackground,
                                        child: const Center(
                                          child: Icon(Icons.error, color: Colors.red),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Delete button overlay
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _deletePhoto(context, index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Social media links (placeholder for future implementation)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Social Media',
                        style: TextStyle(
                          color: AppColors.primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSocialMediaItem(
                              icon: Icons.language,
                              label: 'Website',
                              value: 'Add your website',
                              onTap: () {},
                            ),
                            const Divider(color: AppColors.grayBorder, height: 24),
                            _buildSocialMediaItem(
                              icon: Icons.chat_bubble_outline,
                              label: 'Instagram',
                              value: 'Add Instagram',
                              onTap: () {},
                            ),
                            const Divider(color: AppColors.grayBorder, height: 24),
                            _buildSocialMediaItem(
                              icon: Icons.facebook_outlined,
                              label: 'Facebook',
                              value: 'Add Facebook',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryWhite, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.secondaryWhite,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryWhite, size: 16),
        ],
      ),
    );
  }

  // Helper method to show image source options (camera or gallery)
  void _showImageSourceOptions(BuildContext context, ImageType type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.primaryWhite),
            title: const Text('Take photo', style: TextStyle(color: AppColors.primaryWhite)),
            onTap: () {
              Navigator.pop(context);
              _updateImage(context, ImageSource.camera, type);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.primaryWhite),
            title: const Text('Choose from gallery', style: TextStyle(color: AppColors.primaryWhite)),
            onTap: () {
              Navigator.pop(context);
              _updateImage(context, ImageSource.gallery, type);
            },
          ),
        ],
      ),
    );
  }

  // Update profile or cover image
  void _updateImage(BuildContext context, ImageSource source, ImageType type) {
    setState(() {
      _isLoading = true;
    });

    Future<void> updateAction;

    switch (type) {
      case ImageType.profile:
        updateAction = ref.read(userControllerProvider.notifier).updateProfileImage(context, source);
        break;
      case ImageType.cover:
        updateAction = ref.read(userControllerProvider.notifier).updateCoverPhoto(context, source);
        break;
    }

    updateAction.then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  // Add photos to gallery
  void _addPhotos(BuildContext context) {
    setState(() {
      _isLoading = true;
    });

    ref.read(userControllerProvider.notifier).addPhotos(context).then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  // Delete a photo from gallery
  void _deletePhoto(BuildContext context, int index) {
    // Get the user and photo URL
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.userImages.isEmpty || index >= user.userImages.length) {
      return;
    }

    final photoUrl = user.userImages[index];

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text('Delete Photo', style: TextStyle(color: AppColors.primaryWhite)),
        content: const Text('Are you sure you want to delete this photo?',
            style: TextStyle(color: AppColors.secondaryWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryWhite)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              // ref.read(userControllerProvider.notifier).deletePhoto(context, photoUrl).then((_) {
              //   setState(() {
              //     _isLoading = false;
              //   });
              // }).catchError((error) {
              //   setState(() {
              //     _isLoading = false;
              //   });
              // });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Save bio changes
  void _saveBio(BuildContext context) {
    setState(() {
      _isLoading = true;
      _isEditingBio = false;
    });

    final bio = _bioController.text.trim();
    ref.read(userControllerProvider.notifier).updateBio(context, bio).then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
        _isEditingBio = true; // Revert to editing mode on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bio: $error')),
      );
    });
  }

  // Save name changes
  void _saveName(BuildContext context) {
    setState(() {
      _isLoading = true;
      _isEditingName = false;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _isLoading = false;
        _isEditingName = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    // ref.read(userControllerProvider.notifier).updateName(context, name).then((_) {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }).catchError((error) {
    //   setState(() {
    //     _isLoading = false;
    //     _isEditingName = true; // Revert to editing mode on error
    //   });
    // });
  }

  // Show full screen image
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ImageType {
  profile,
  cover
}