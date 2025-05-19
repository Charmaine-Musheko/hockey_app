import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'package:hockey_union_app/wrapper.dart'; // Import your Wrapper widget

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
      backgroundColor: Colors.white, // Or your desired background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Your App Logo/Icon ---
            // Replace this with your actual logo asset
            // Example using an asset image (add image to pubspec.yaml and project)
            // Image.asset(
            //   'assets/images/your_logo.png', // Your logo asset path
            //   width: 150, // Adjust size as needed
            //   height: 150,
            // ),
            Icon( // Placeholder icon
              Icons.sports_hockey,
              size: 100,
              color: Colors.blue, // Placeholder color
            ),
            SizedBox(height: 20),
            Text(
              'Namibia Hockey Union',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Placeholder color
              ),
            ),
            // Add a loading indicator if you want
            // SizedBox(height: 30),
            // CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
