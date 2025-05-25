import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;

  PermissionService._internal();

  Future<bool> requestInitialPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
      Permission.location,
    ].request();

    bool allGranted = true;
    for (var status in statuses.values) {
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    if (allGranted) {
      // Initialize location service after permissions granted
      final location = loc.Location();
      await location.requestService();
      await location.requestPermission();
    }

    return allGranted;
  }

  // Add new method to handle notification permission specifically
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // Opens app settings so user can enable notification permission
      await openAppSettings();
      return false;
    }
    return false;
  }

  // Check notification permission status
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }
}
