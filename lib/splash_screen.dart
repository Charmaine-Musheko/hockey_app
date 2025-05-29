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
            Image.asset(
              'assets/images/IMG_7434.png', // Path to your logo
              height: 120, // Adjust height as needed
              fit: BoxFit.contain, // Ensures the entire image is visible within its bounds
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