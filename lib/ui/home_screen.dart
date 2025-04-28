import 'package:flutter/material.dart';
import 'package:hockey_union_app/ui/home_screen.dart';
import 'package:hockey_union_app/ui/teams_registration_screen.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Namibia Hockey Union'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Register a Team'),
              onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeamRegistrationScreen()),
                    );
                  },
            ),
            ElevatedButton(
              child: Text('Enter Event'),
              onPressed: () {
                // navigate to Event Entries
              },
            ),
            ElevatedButton(
              child: Text('Manage Players'),
              onPressed: () {
                // navigate to Player Management
              },
            ),
            ElevatedButton(
              child: Text('Real-time Info'),
              onPressed: () {
                // navigate to News/Updates
              },
            ),
          ],
        ),
      ),
    );
  }
}
