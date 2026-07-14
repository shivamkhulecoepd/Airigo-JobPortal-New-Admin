import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui';

/// Background message handler - MUST be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background,
  // ensure that you call WidgetsFlutterBinding.ensureInitialized() before
  // using other Firebase plugins.
  print('Handling a background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}
