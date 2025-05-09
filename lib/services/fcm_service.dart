import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For defaultTargetPlatform
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notifications
import 'package:flutter/material.dart'; // Import Material for navigation context (we'll need a NavigatorKey)


class FcmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // We need a way to access the Navigator state from outside a widget's build method.
  // A GlobalKey is a common way to do this.
  // You should define this key in your main.dart or a navigation service
  // and assign it to your MaterialApp or CupertinoApp's navigatorKey.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


  // Function to save the FCM token to Firestore
  Future<void> saveTokenToFirestore(String? token) async { /* ... */ }

  // Initialize FCM and set up listeners
  Future<void> initializeFcm() async { /* ... */ }

  // Helper function to show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async { /* ... */ }

  // --- Notification Tap Handling Logic ---
  // This function will be called when a notification is tapped (foreground, background, terminated)
  // Making this public so it can be called from main.dart for terminated state handling
  void handleNotificationTap(String? payload) { // <--- THIS METHOD MUST BE PUBLIC AND NAMED handleNotificationTap
    if (payload == null) {
      print('Notification tap with null payload.');
      return;
    }

    print('Handling notification tap with payload: $payload');

    // TODO: Parse the payload and navigate the user
    // The payload should contain data that tells you where to navigate.
    // For example, a payload could be a JSON string like:
    // {'type': 'match', 'id': 'match_doc_id'}
    // {'type': 'news', 'id': 'news_doc_id'}
    // {'type': 'event', 'id': 'event_doc_id'}

    // Basic example parsing (you'll need a more robust JSON parser for real data)
    // Assuming payload is a simple string indicating type and ID separated by ':'
    final parts = payload.split(':');
    if (parts.length != 2) {
      print('Invalid notification payload format: $payload');
      return;
    }

    final String type = parts[0];
    final String id = parts[1];

    // Use the navigatorKey to navigate
    if (navigatorKey.currentState != null) {
      switch (type) {
        case 'match':
        // TODO: Navigate to Match Detail Screen
        // Requires importing the screen and potentially passing userId if needed
        // navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => MatchDetailScreen(matchId: id)));
          print('Attempting to navigate to Match Detail with ID: $id');
          break;
        case 'news':
        // TODO: Navigate to News Detail Screen (if you create one)
        // Requires importing the screen
        // navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => NewsDetailScreen(newsId: id)));
          print('Attempting to navigate to News Detail with ID: $id');
          break;
        case 'event':
        // TODO: Navigate to Event Detail Screen
        // Requires importing the screen
        // navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventId: id)));
          print('Attempting to navigate to Event Detail with ID: $id');
          break;
      // Add more cases for other types of notifications
        default:
          print('Unknown notification type: $type');
          // Maybe navigate to the Home Screen or a generic notification list
          // navigatorKey.currentState!.pushReplacementNamed('/'); // Example: Navigate to Home
          break;
      }
    } else {
      print('NavigatorKey is not assigned or current state is null.');
      // This can happen if the app hasn't finished building or the key isn't set up correctly.
      // You might need to handle this case, perhaps by storing the payload and navigating later.
    }
  }
  // --- End Notification Tap Handling Logic ---


  // Optional: Method to delete the token (e.g., on logout from a specific device)
  Future<void> deleteToken() async { /* ... */ }

// TODO: Implement onDidReceiveLocalNotification for iOS < 10.0 if needed
// void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async { /* ... */ }

// TODO: Implement onDidReceiveBackgroundNotificationResponse for Android 12+
// @pragma('vm:entry-point') // Required for background notification response handler
// void onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) { /* ... */ }
}
    