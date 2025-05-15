import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For defaultTargetPlatform
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notifications
import 'package:flutter/material.dart';

import '../ui/events/events_detail.dart'; // Import Material for navigation context (we'll need a NavigatorKey)


// TODO: Import NewsDetailScreen if you create one
// import 'package:hockey_union_app/ui/news/news_detail_screen.dart';


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
  Future<void> saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final currentUser = _firebaseAuth.currentUser;

    if (currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('fcmTokens')
            .doc(token)
            .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.toString(),
        }, SetOptions(merge: true));

        print('FCM token saved for user ${currentUser.uid}');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    } else {
      print('FCM token obtained, but no user logged in. Token: $token');
      // TODO: Implement logic for tokens obtained before login if necessary
      // Maybe store the token in a temporary collection and link it when they log in.
    }
  }

  // Initialize FCM and set up listeners
  Future<void> initializeFcm() async {
    // Background handler is registered in main.dart

    // --- Local Notifications Setup ---
    // Initialize the plugin for different platforms
    // Corrected: Replace 'app_icon' with the actual name of your launcher icon drawable resource
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // <-- Change this to your icon name (e.g., 'ic_launcher')

    // TODO: Add iOS Initialization Settings if needed
    // const DarwinInitializationSettings initializationSettingsDarwin =
    //    DarwinInitializationSettings(
    //      onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Implement this callback for iOS < 10.0
    //    );

    // TODO: Add Linux/macOS/Windows Initialization Settings if needed
    // final LinuxInitializationSettings initializationSettingsLinux =
    //    LinuxInitializationSettings(
    //      defaultActionName: 'Open notification',
    //    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsDarwin, // Uncomment and provide iOS settings
      // linux: initializationSettingsLinux, // Uncomment and provide Linux settings
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Implement onDidReceiveNotificationResponse to handle tapping notifications
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Handle notification tap here when app is in foreground
        print('Foreground notification tapped! Payload: ${notificationResponse.payload}');
        // Call the handler function
        handleNotificationTap(notificationResponse.payload);
      },
      // TODO: Implement onDidReceiveBackgroundNotificationResponse for Android 12+
      // onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse, // For background taps (Android 12+)
    );
    print('FlutterLocalNotificationsPlugin initialized.');
    // --- End Local Notifications Setup ---


    // Request notification permissions (FCM handles this, but local plugin might need it too on some platforms)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true, announcement: false, badge: true, carPlay: false,
      criticalAlert: false, provisional: false, sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');


    // Get the initial token and save it if a user is already logged in
    String? initialToken = await _firebaseMessaging.getToken();
    print('Initial FCM Token: $initialToken');
    // Token saving is handled by Auth Service on login/signup and onTokenRefresh listener


    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token Refreshed: $newToken');
      saveTokenToFirestore(newToken); // Save the new token to Firestore
    });

    // Handle messages received while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Display a local notification to the user here
        _showLocalNotification(message);
      }
    });

    // Handle messages received when the app is opened from a terminated state
    // This part is handled in main.dart's getInitialMessage handler, which calls this public method.


    // Handle messages received when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background by tapping notification!');
      print('Message data: ${message.data}');
      // Call the handler function
      handleNotificationTap(message.data['payload']);
    });
  }

  // Helper function to show a local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'hockey_union_channel_id', // Channel ID (can be anything unique)
      'Hockey Union Notifications', // Channel name (user visible)
      channelDescription: 'Notifications from Hockey Union App', // Channel description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      // Optional: Set a custom icon for the notification (if different from app icon)
      // You would add 'notification_icon_name' here if you have a specific icon for notifications
      // icon: 'notification_icon_name',
    );

    // TODO: Add iOS Notification Details if needed
    // const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    //     DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      // iOS: iOSPlatformChannelSpecifics, // Uncomment and provide iOS settings
    );

    // Display the notification
    await flutterLocalNotificationsPlugin.show(
      message.hashCode, // Use a unique ID for each notification (e.g., hash of message)
      message.notification?.title ?? 'Notification', // Notification title
      message.notification?.body ?? 'New message', // Notification body
      platformChannelSpecifics,
      payload: message.data['payload'], // Optional: Pass data with the notification
    );
    print('Local notification shown.');
  }

  // --- Notification Tap Handling Logic ---
  // This function will be called when a notification is tapped (foreground, background, terminated)
  // Making this public so it can be called from main.dart for terminated state handling
  void handleNotificationTap(String? payload) { // Removed underscore to make it public
    if (payload == null || navigatorKey.currentState == null) {
      print('Notification tap with null payload or navigatorKey not ready.');
      return;
    }

    print('Handling notification tap with payload: $payload');

    // Parse the payload to determine where to navigate.
    // Assuming payload is a simple string indicating type and ID separated by ':'
    // Example payload format: 'type:id' (e.g., 'match:abc123', 'event:xyz789')
    final parts = payload.split(':');
    if (parts.length != 2) {
      print('Invalid notification payload format: $payload');
      // Optionally navigate to a default screen (e.g., Home) for invalid payloads
      // navigatorKey.currentState!.pushReplacementNamed('/');
      return;
    }

    final String type = parts[0];
    final String id = parts[1];

    // Use the navigatorKey to navigate
    switch (type) {
      case 'match':
      // Navigate to Match Detail Screen
      // You'll need to import MatchScheduleScreen (or your MatchDetailScreen)
      // and potentially pass the userId if that screen requires it.
      // For now, let's navigate to MatchScheduleScreen as a placeholder,
      // but ideally you'd navigate to a specific Match Detail screen.
      // Note: MatchScheduleScreen requires userId. You might need to fetch it
      // or pass it differently if navigating directly from a notification tap.
      // A dedicated MatchDetailScreen that only needs matchId is better.
        print('Attempting to navigate to Match Detail (via MatchScheduleScreen placeholder) with ID: $id');
        // This navigation might require the user to be logged in.
        // If the app is opened from terminated/background, the Wrapper will handle auth first.
        // If app is foreground, user is already logged in.
        // You might need to pass the current userId here if MatchScheduleScreen requires it.
        // For now, let's skip navigation to MatchScheduleScreen directly as it's complex without userId.
        // TODO: Implement a dedicated MatchDetailScreen that takes only matchId and fetch data within it.
        // Example navigation to a hypothetical MatchDetailScreen:
        // navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => MatchDetailScreen(matchId: id)));
        break;

      case 'news':
      // TODO: Navigate to News Detail Screen (if you create one)
      // Requires importing the screen
      // Example navigation:
      // navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => NewsDetailScreen(newsId: id)));
        print('Attempting to navigate to News Detail with ID: $id');
        break;

      case 'event':
      // Navigate to Event Detail Screen
      // Requires importing EventDetailScreen
        print('Attempting to navigate to Event Detail with ID: $id');
        navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventId: id)));
        break;

    // Add more cases for other types of notifications (e.g., 'team', 'player')
    // case 'team':
    //   navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => TeamProfileScreen(teamId: id)));
    //   break;
    // case 'player':
    //   navigatorKey.currentState!.push(MaterialPageRoute(builder: (context) => PlayerProfileScreen(playerId: id)));
    //   break;

      default:
        print('Unknown notification type: $type');
        // Navigate to a default screen (e.g., Home) for unknown types
        navigatorKey.currentState!.pushReplacementNamed('/'); // Example: Navigate to Home
        break;
    }
  }
  // --- End Notification Tap Handling Logic ---


  // Optional: Method to delete the token (e.g., on logout from a specific device)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      print('FCM token deleted for this device.');
      // TODO: Also remove the token from Firestore for the current user/device
      // You'll need the current user's UID and the token to remove the specific token document.
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

// TODO: Implement onDidReceiveLocalNotification for iOS < 10.0 if needed
// void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
//   // Process notification received while app is in foreground (iOS < 10.0)
//   handleNotificationTap(payload); // Call the public handler
// }

// TODO: Implement onDidReceiveBackgroundNotificationResponse for Android 12+
// @pragma('vm:entry-point') // Required for background notification response handler
// void onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
//   // Handle notification tap when app is in background (Android 12+)
//   handleNotificationTap(notificationResponse.payload); // Call the public handler
// }
}
