import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'package:hockey_union_app/utils/app_colors.dart';
import 'package:hockey_union_app/wrapper.dart'; // Import your new AppColors

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start a timer to navigate to the next screen after a delay
    Timer(
      Duration(seconds: 3), // Adjust the duration as needed
          () => Navigator.pushReplacement( // Use pushReplacement to prevent going back to splash
        context,
        MaterialPageRoute(builder: (context) => Wrapper()), // Navigate to your Wrapper
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // You can customize this screen's appearance
    return Scaffold(
      backgroundColor: AppColors.primaryGreen, // Dark green background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Your App Logo/Icon ---
            // TODO: Replace this with your actual logo asset (e.g., Image.asset('assets/images/your_logo.png'))
            // Make sure to add the asset to your pubspec.yaml and project folder.
            // For now, using a placeholder icon that looks like a hockey player.
            // If you have the SVG from the image, you'd use a package like flutter_svg
            // and load it, or convert it to a PNG asset.
            Icon( // Placeholder icon resembling a hockey player
              Icons.sports_hockey, // A generic sports icon
              size: 150,
              color: AppColors.accentOrange, // Orange/Gold color
            ),
            SizedBox(height: 30),
            Text(
              'Namibia Hockey Union',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.white, // White text
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Uniting Hockey in Namibia', // Tagline or subtitle
              style: TextStyle(
                fontSize: 18,
                color: AppColors.white.withOpacity(0.8), // Slightly transparent white
              ),
              textAlign: TextAlign.center,
            ),
            // Add a loading indicator if you want
            // SizedBox(height: 30),
            // CircularProgressIndicator(color: AppColors.accentOrange),
          ],
        ),
      ),
    );
  }
}