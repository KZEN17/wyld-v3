import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<bool> isEmulator() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    try {
      final androidInfo = await deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice;
    } catch (e) {
      return false;
    }
  } else if (Platform.isIOS) {
    try {
      final iosInfo = await deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    } catch (e) {
      return false;
    }
  }
  return false;
}
