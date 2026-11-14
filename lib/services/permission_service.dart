import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'platform_channel.dart';

class PermissionService {
  const PermissionService._();

  static Future<bool> checkAndRequestGalleryPermission() async {
    if (!Platform.isAndroid) return true;

    final int sdkInt = await PlatformChannel.getSdkInt();
    if (sdkInt >= 33) return true;

    final PermissionStatus statusStorage = await Permission.storage.status;
    if (statusStorage.isGranted || statusStorage.isLimited) return true;

    final PermissionStatus statusPhotos = await Permission.photos.status;
    if (statusPhotos.isGranted || statusPhotos.isLimited) return true;

    if (statusStorage.isPermanentlyDenied && statusPhotos.isPermanentlyDenied) {
      await PlatformChannel.openAppInfoSettings();
      return false;
    }

    final Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
    ].request();

    final PermissionStatus reqStorage =
        statuses[Permission.storage] ?? PermissionStatus.denied;
    final PermissionStatus reqPhotos =
        statuses[Permission.photos] ?? PermissionStatus.denied;

    return reqStorage.isGranted ||
        reqStorage.isLimited ||
        reqPhotos.isGranted ||
        reqPhotos.isLimited;
  }
}