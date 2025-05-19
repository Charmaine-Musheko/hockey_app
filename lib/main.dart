import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hockey_union_app/services/auth_service.dart';
import 'package:hockey_union_app/services/fcm_service.dart';
import 'package:hockey_union_app/splash_screen.dart';
import 'package:hockey_union_app/ui/authentication/auth_screen.dart';
import 'package:hockey_union_app/ui/home_screen.dart';
import 'package:hockey_union_app/wrapper.dart';
import 'database/firebase_options.dart';


// Define a top-level or static function to handle background messages
// This function must not be an anonymous function, must be a top-level function,
// and cannot change any application state.
// This handler is still needed here because Firebase needs a top-level function reference.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure to call `initializeApp` before using them.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Ensure Firebase is initialized
  print('Handling a background message: ${message.messageId}');
  // TODO: You can process the message here (e.g., save to local storage, trigger local notification)
  // For example, you could trigger a local notification here to alert the user.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- FCM Setup ---
  // 1. Register the background handler (still needs to be top-level)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. Initialize FcmService and set up listeners
  final fcmService = FcmService();
  await fcmService.initializeFcm(); // Call the initialization method from FcmService

  // The rest of the FCM setup (requestPermission, getToken, onTokenRefresh,
  // onMessage, getInitialMessage, onMessageOpenedApp) is now handled
  // inside the FcmService.initializeFcm() method, EXCEPT for the initial message handler below.

  // 3. Handle messages received when the app is opened from a terminated state
  // This is for when the app is completely closed and the user taps the notification.
  // We need to get the initial message and pass its payload to our handler.
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('App opened from terminated state by tapping notification!');
      print('Initial Message data: ${message.data}');
      // Call the public handler function from FcmService with the payload
      if (message.data['payload'] != null) {
        // We need to ensure the NavigatorKey is ready before attempting navigation.
        // A common pattern is to add a small delay or use a post-frame callback.
        // For simplicity here, we'll add a small delay.
        Future.delayed(Duration(milliseconds: 500), () { // Add a slight delay
          // Call the public handleNotificationTap method on a new FcmService instance
          // Pass the payload from the notification data
          fcmService.handleNotificationTap(message.data['payload']);
        });
      }
    }
  });

  // The onMessage and onMessageOpenedApp listeners are handled within FcmService.initializeFcm()

  // --- End FCM Setup ---

  runApp(HockeyUnionApp()); // Your main app widget, which should start with Wrapper()
}


class HockeyUnionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hockey Union App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: FcmService.navigatorKey, // Assign the GlobalKey here
      home: SplashScreen(),
    );
  }
}
