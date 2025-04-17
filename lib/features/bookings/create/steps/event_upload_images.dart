// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/full_width_button.dart';
import '../../controllers/event_controller.dart';
import '../../screens/widgets/create_venue_appbar.dart';

class EventImageUpload extends ConsumerStatefulWidget {
  final String eventId;

  const EventImageUpload({super.key, required this.eventId});

  @override
  ConsumerState<EventImageUpload> createState() => _EventImageUploadState();
}

class _EventImageUploadState extends ConsumerState<EventImageUpload> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreateTabAppbar(
        onTap: () {
          _deleteEvent();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add venue photos',
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 28.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Add photos of your venue to attract more guests',
              style: TextStyle(color: AppColors.secondaryWhite, fontSize: 16.0),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child:
                  _selectedImages.isEmpty
                      ? _buildEmptyState()
                      : _buildImageGrid(),
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
            FullWidthButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20.0,
              ),
              name:
                  _selectedImages.isEmpty
                      ? 'Skip for now'
                      : 'Upload and continue',
              onPressed:
                  _selectedImages.isEmpty ? _skipImageUpload : _uploadImages,
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              Icons.image,
              size: 80,
              color: AppColors.primaryPink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // The last item is the add button
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.grayBorder,
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate,
                      size: 40,
                      color: AppColors.primaryPink,
                    ),
                  ),
                );
              }
              // Other items are the selected images
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          '${_selectedImages.length} photos selected',
          style: const TextStyle(
            color: AppColors.secondaryWhite,
            fontSize: 14.0,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            _selectedImages.add(File(file.path));
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      _skipImageUpload();
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Convert File objects to paths
      _selectedImages.map((file) => file.path).toList();

      // Upload images using the event controller
      await ref
          .read(eventControllerProvider.notifier)
          .uploadEventImages(widget.eventId, _selectedImages);

      if (!mounted) return;

      // Navigate to the next screen
      Navigator.of(
        context,
      ).pushNamed('/invite-contacts', arguments: widget.eventId);
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        print(e);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _skipImageUpload() {
    Navigator.of(
      context,
    ).pushNamed('/invite-contacts', arguments: widget.eventId);
  }

  void _deleteEvent() async {
    try {
      await ref
          .read(eventControllerProvider.notifier)
          .deleteEvent(widget.eventId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting event: $e')));
    }
  }
}
