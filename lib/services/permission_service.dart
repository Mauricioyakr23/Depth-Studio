import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'platform_channel.dart';

class PermissionService {
  const PermissionService._();

  static Future<bool> checkAndRequestGalleryPermission() async {
    if (Platform.isAndroid) {
      final int sdkInt = await PlatformChannel.getSdkInt();
      if (sdkInt >= 33) return true;
    }
    final PermissionStatus statusPhotos = await Permission.photos.status;
    if (statusPhotos.isGranted) return true;

    final PermissionStatus statusStorage = await Permission.storage.status;
    if (statusStorage.isGranted) return true;

    final Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.storage,
    ].request();

    return statuses[Permission.photos] == PermissionStatus.granted ||
        statuses[Permission.storage] == PermissionStatus.granted;
  }
}