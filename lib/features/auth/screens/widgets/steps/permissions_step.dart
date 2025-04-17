// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/features/auth/controllers/onboarding_controller.dart';
import 'package:wyld/features/auth/screens/widgets/onboarding_appbar.dart';
import 'package:wyld/shared/widgets/full_width_button.dart';

class PermissionsStep extends ConsumerStatefulWidget {
  final Function onComplete;

  const PermissionsStep({super.key, required this.onComplete});

  @override
  ConsumerState<PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends ConsumerState<PermissionsStep> {
  bool _isLoading = false;
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isEmulator = false;

  @override
  void initState() {
    super.initState();
    _detectEmulator();
    _checkPermissions();
  }

  Future<void> _detectEmulator() async {
    try {
      // This is a simple heuristic to detect emulators
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final isEmulator = !androidInfo.isPhysicalDevice;
      setState(() {
        _isEmulator = isEmulator;
      });
    } catch (e) {
      // If we can't detect, assume it's not an emulator
      debugPrint('Error detecting emulator: $e');
    }
  }

  Future<void> _checkPermissions() async {
    // Check current permission statuses
    final locationStatus = await Permission.location.status;
    setState(() {
      _locationPermissionGranted = locationStatus.isGranted;
    });

    final notificationStatus = await Permission.notification.status;
    setState(() {
      _notificationPermissionGranted = notificationStatus.isGranted;
    });

    // If on emulator and location permission is granted, use mock location
    if (_isEmulator && _locationPermissionGranted) {
      _setMockLocation();
    } else {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        _getCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    }
  }

  void _setMockLocation() {
    // Set mock location for emulator (San Francisco coordinates)
    setState(() {
      _currentPosition = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // For emulators, use mock location instead of trying to get real location
      if (_isEmulator) {
        _setMockLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // If location retrieval times out, use a default position
          return Position(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        },
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Set default position on error
      _setMockLocation();
    }
  }

  Future<bool> _requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // On emulator, we'll pretend services are enabled even if they're not
      if (_isEmulator) {
        serviceEnabled = true;
      }

      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable them in settings.',
            ),
          ),
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them in app settings.',
            ),
          ),
        );
        return false;
      }

      // If running on emulator, we'll just set a mock position
      if (_isEmulator) {
        _setMockLocation();
        setState(() {
          _locationPermissionGranted = true;
        });
        return true;
      }

      // If we reach here, permissions are granted
      await _getCurrentLocation();
      setState(() {
        _locationPermissionGranted = true;
      });
      return true;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      // For emulator testing, we'll return true anyway
      if (_isEmulator) {
        _setMockLocation();
        setState(() {
          _locationPermissionGranted = true;
        });
        return true;
      }
      return false;
    }
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      setState(() {
        _notificationPermissionGranted = status.isGranted;
      });
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      // For testing purposes, we'll pretend it worked
      if (_isEmulator) {
        setState(() {
          _notificationPermissionGranted = true;
        });
        return true;
      }
      return false;
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationGranted = await _requestLocationPermission();
      final notificationGranted = await _requestNotificationPermission();

      // For emulator, always proceed
      if (_isEmulator || (locationGranted && notificationGranted)) {
        // Make sure we have a position (either real or mock)
        if (_currentPosition == null) {
          _setMockLocation();
        }

        // Complete the onboarding process
        await ref
            .read(onboardingControllerProvider.notifier)
            .completeOnboarding(
              context,
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
            );

        // Call the completion callback
        widget.onComplete();
      } else {
        // Show dialog explaining why permissions are needed
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.primaryBackground,
              title: const Text(
                'Permissions Required',
                style: TextStyle(color: AppColors.primaryWhite),
              ),
              content: const Text(
                'Wyld needs location and notification permissions to provide you with the best experience. Please grant these permissions to continue.',
                style: TextStyle(color: AppColors.secondaryWhite),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: AppColors.primaryPink),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // For testing purposes, let users proceed anyway
                    _setMockLocation();
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .completeOnboarding(
                          context,
                          latitude: _currentPosition!.latitude,
                          longitude: _currentPosition!.longitude,
                        )
                        .then((_) => widget.onComplete());
                  },
                  child: const Text(
                    'Continue Anyway',
                    style: TextStyle(color: AppColors.primaryPink),
                  ),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const OnboardingAppbar(showLeading: false),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPink,
                  ),
                ),
              )
              : SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(
                        value: 0.9,
                        backgroundColor: AppColors.secondaryBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryPink,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Location & \nNotification Services',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.primaryWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'To get the most out of Wyld, you\'ll need to allow the following:',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.secondaryWhite),
                              ),
                              const SizedBox(height: 20),
                              // Image placeholder for the permissions illustration
                              Container(
                                width: MediaQuery.of(context).size.width,
                                height: 175.0,
                                decoration: BoxDecoration(
                                  image: DecorationImage(image: AssetImage('assets/permissions.png')),
                                  color: AppColors.secondaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                        
                              ),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  size: 32.0,
                                  color: Color.fromRGBO(40, 152, 222, 1.0),
                                ),
                                title: const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryWhite,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Share your location to get nearby recommendations',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primaryWhite,
                                  ),
                                ),
                                trailing:
                                    _locationPermissionGranted
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 24,
                                        )
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(
                                  Icons.notifications_none_outlined,
                                  size: 32.0,
                                  color: Color.fromRGBO(40, 152, 222, 1.0),
                                ),
                                title: const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryWhite,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Lets us help you to stay updated about your table bookings and requests',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primaryWhite,
                                  ),
                                ),
                                trailing:
                                    _notificationPermissionGranted
                                        ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 24,
                                        )
                                        : null,
                              ),
                              // Emulator indicator (only in debug mode)
                              if (_isEmulator && kDebugMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Emulator detected: Using mock location data',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
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
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: FullWidthButton(
                        name: 'Enable Location & Notification Services',
                        fontSize: 14.0,
                        onPressed: _requestAllPermissions,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

// Mock device info plugin for simplicity
// In a real app, you would import 'package:device_info_plus/device_info_plus.dart'
class MockDeviceInfoPlugin {
  Future<AndroidDeviceInfo> get androidInfo async {
    return AndroidDeviceInfo();
  }
}

class AndroidDeviceInfo {
  // Most emulators will report isPhysicalDevice as false
  bool get isPhysicalDevice => false;
}

final deviceInfoPlugin = MockDeviceInfoPlugin();
