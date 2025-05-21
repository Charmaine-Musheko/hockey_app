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
import 'package:hockey_union_app/utils/app_colors.dart';
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
        // Use your new primary green color
        primaryColor: AppColors.primaryGreen,
        // Define a color scheme for better Material 3 integration (optional but good practice)
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(AppColors.primaryGreen.value, {
            50: AppColors.primaryGreen.withOpacity(0.1),
            100: AppColors.primaryGreen.withOpacity(0.2),
            200: AppColors.primaryGreen.withOpacity(0.3),
            300: AppColors.primaryGreen.withOpacity(0.4),
            400: AppColors.primaryGreen.withOpacity(0.5),
            500: AppColors.primaryGreen,
            600: AppColors.primaryGreen.withOpacity(0.7),
            700: AppColors.primaryGreen.withOpacity(0.8),
            800: AppColors.primaryGreen.withOpacity(0.9),
            900: AppColors.primaryGreen.withOpacity(1.0),
          }),
          accentColor: AppColors.accentOrange, // Use your accent color
        ).copyWith(
          background: AppColors.primaryGreen, // Overall app background
          surface: AppColors.white, // For cards, sheets, etc.
          secondary: AppColors.accentOrange, // Ensure accentColor is set as secondary
        ),

        // Customize AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryGreen, // Dark green AppBar
          foregroundColor: AppColors.white, // White text/icons on AppBar
          centerTitle: true, // Center title by default
          elevation: 0, // No shadow for a flat look
        ),

        // Customize ElevatedButton theme for consistent button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange, // Orange/Gold buttons
            foregroundColor: AppColors.white, // White text on buttons
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Consistent padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded corners for buttons
            ),
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Customize TextButton theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentOrange, // Orange/Gold text buttons
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Customize input field decoration (for TextFormField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white, // White background for input fields
          labelStyle: TextStyle(color: AppColors.primaryGreen), // Green label text
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners for input fields
            borderSide: BorderSide.none, // No border by default
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5), width: 1.0), // Light green border when enabled
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2.0), // Stronger green border when focused
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Padding inside the field
        ),

        // Customize Card theme
        cardTheme: CardTheme(
          elevation: 4.0, // Add some shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners for cards
          ),
          color: AppColors.white, // White background for cards
        ),

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // Start with the SplashScreen
    );
  }
}
