import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:elang_dashboard_new_ui/services/background_update_service.dart';
import 'package:elang_dashboard_new_ui/services/firebase_options.dart';

class FCMService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseMessaging.instance.subscribeToTopic('app_updates');

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.data['type'] == 'update') {
          BackgroundUpdateService().checkForUpdateInBackground();
        }
      });
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      // ignore: empty_catches
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (message.data['type'] == 'update') {
        await BackgroundUpdateService().checkForUpdateInBackground();
      }
    } catch (e) {
      // ignore: empty_catches
    }
  }
}
