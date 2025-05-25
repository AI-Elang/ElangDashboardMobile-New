import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = BackgroundUpdateService();
      await service.checkForUpdateInBackground();
      return true;
    } catch (err) {
      return false;
    }
  });
}

class BackgroundUpdateService {
  static const String VERSION_CHECK_URL =
      "https://raw.githubusercontent.com/AI-Elang/ElangDashboardUpdateApp-New/main/version.json";

  static final BackgroundUpdateService _instance =
      BackgroundUpdateService._internal();
  factory BackgroundUpdateService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  BackgroundUpdateService._internal();

  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize WorkManager
    await Workmanager().initialize(callbackDispatcher);

    // Start periodic task
    await Workmanager().registerPeriodicTask(
      "version-check",
      "checkVersion",
      frequency: const Duration(minutes: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    // Initialize notifications
    await _initializeNotifications();

    // Setup Firebase Messaging
    await _setupFirebaseMessaging();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    const channel = AndroidNotificationChannel(
      'update_channel',
      'App Updates',
      description: 'Notifications for app updates',
      importance: Importance.high,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    if (message.data.containsKey('version')) {
      final service = BackgroundUpdateService();
      await service.checkForUpdateInBackground();
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.data.containsKey('version')) {
      await checkForUpdateInBackground();
    }
  }

  Future<void> checkForUpdateInBackground() async {
    try {
      final updateInfo = await _compareVersions();
      if (updateInfo != null) {
        await _showUpdateNotification(updateInfo);
      }
    } catch (e) {
      print('Background update check error: $e');
    }
  }

  Future<void> _showUpdateNotification(Map<String, dynamic> updateInfo) async {
    const androidDetails = AndroidNotificationDetails(
      'update_channel',
      'App Updates',
      channelDescription: 'Notifications for app updates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      autoCancel: false,
      ongoing: true,
    );

    await _notificationsPlugin.show(
      0,
      'Pembaruan Tersedia',
      'Versi ${updateInfo['version']} telah tersedia! Ketuk untuk mengupdate.',
      const NotificationDetails(android: androidDetails),
      payload: 'update',
    );
  }

  Future<Map<String, dynamic>?> _compareVersions() async {
    try {
      final response = await http.get(Uri.parse(VERSION_CHECK_URL));
      if (response.statusCode != 200) return null;

      final remoteConfig = json.decode(response.body);
      final packageInfo = await PackageInfo.fromPlatform();

      final installedVersion = packageInfo.version;
      final installedBuild = int.parse(packageInfo.buildNumber);
      final remoteVersion = remoteConfig['version'].toString();
      final remoteBuild = remoteConfig['build_number'] as int;

      if (_isUpdateRequired(
        installedVersion,
        installedBuild,
        remoteVersion,
        remoteBuild,
      )) {
        return remoteConfig;
      }
      return null;
    } catch (e) {
      print('Version comparison error: $e');
      return null;
    }
  }

  bool _isUpdateRequired(
    String currentVersion,
    int currentBuild,
    String remoteVersion,
    int remoteBuild,
  ) {
    final List<int> current = currentVersion.split('.').map(int.parse).toList();
    final List<int> remote = remoteVersion.split('.').map(int.parse).toList();

    if (remote[0] != current[0]) return remote[0] > current[0];
    if (remote[1] != current[1]) return remote[1] > current[1];
    if (remote[2] != current[2]) return remote[2] > current[2];
    return remoteBuild > currentBuild;
  }
}
