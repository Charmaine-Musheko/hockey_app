Namibia Hockey Union Mobile Application
Project Overview
This project is a mobile application developed for the Namibia Hockey Union using Flutter and Firebase. The app aims to provide a platform for managing hockey-related information, including teams, players, match schedules, events, news, and user-specific functionalities based on roles.

Features
The application includes the following key features:

User Authentication: Secure email and password-based registration and login.

Role-Based Access Control: Different user roles (Fan, Player, Coach, Admin) determine access to specific features and content.

Team Management:

View a list of all registered teams.

Register new teams (Coach/Admin).

Player Management:

Register new players (Coach/Admin).

Manage player profiles, including stats (goals, assists, games played) and achievements.

Link player profiles to user accounts.

Match Management:

View the upcoming match schedule.

Add and edit match details (Coach/Admin).

Display match scores for completed/in-progress matches.

Event Management:

View a list of upcoming events.

View detailed information about events (date, location, description, ticket info).

Add and edit event details (Coach/Admin).

Booking System:

Book spots for scheduled matches (Authenticated users).

Book tickets/spots for events (Authenticated users), with basic ticket availability tracking.

View a list of the logged-in user's bookings.

News and Announcements:

View a feed of news items and announcements.

Publish new news items (Coach/Admin).

Player Profile:

Dedicated screen for users with the 'Player' role to view their personal stats and achievements.

Splash Screen: A welcoming screen displayed on app startup.

Sleek UI: Enhanced user interface design with a navy blue color contrast.

Technologies Used
Framework: Flutter (vX.Y.Z - Replace with your Flutter version)

Backend: Firebase

Firebase Authentication

Firestore (NoSQL Database)

Firebase Cloud Messaging (FCM) - Initial setup for push notifications

Packages:

cloud_firestore

firebase_auth

firebase_core

firebase_messaging

intl

flutter_local_notifications

List any other significant packages you added

Setup and Installation
Clone the Repository:

git clone <repository_url>
cd <repository_name>

Install Dependencies:

flutter pub get

Firebase Project Setup:

Create a new Firebase project in the Firebase Console.

Add a Flutter app to your Firebase project. Follow the instructions to add the necessary configuration files (google-services.json for Android, GoogleService-Info.plist for iOS).

Enable Authentication (Email/Password provider).

Enable Firestore Database (Start in production mode and set up security rules).

Enable Cloud Messaging.

Configure Firebase Options:

Ensure your lib/firebase_options.dart file is correctly generated and configured for your project.

Set Up Firestore Security Rules:

Go to Firestore Database -> Rules in your Firebase Console.

Replace the default rules with the rules provided in the project (refer to the firestore_rules_with_player_read or latest security rules artifact). Remember to Publish the rules.

Create Firestore Indexes:

Check your console output for FAILED_PRECONDITION errors when running queries involving filtering and ordering (e.g., players by teamId, bookings by userId).

Click the links provided in the console output to create the necessary composite indexes in your Firebase Console (Firestore Database -> Indexes). Wait for them to build.

Run the Application:

Connect a device or start an emulator.

Run the app from your terminal:

flutter run

Or run from your IDE (VS Code, Android Studio).

Usage
Upon launching, you will see a splash screen followed by the Authentication screen.

Sign up for a new account or sign in with existing credentials.

The app will navigate to the Home screen, where available features are displayed based on your user role.

Ensure you create user documents in Firestore and set the role field to 'Fan', 'Player', 'Coach', or 'Admin' to test different access levels.

For 'Player' role testing, create a player document in the players collection and set the userId field to the UID of your test user account.

Contributing
Fork the repository.

Create a new branch (git checkout -b feature/your-feature).

Make your changes and commit them (git commit -m 'Add some feature').

Push to the branch (git push origin feature/your-feature).

Open a Pull Request.

License
Specify your project's license here (e.g., MIT, Apache 2.0)

Contact
Student Name: Charmaine Musheko

Student Number: 219148872

Add any other contact information or links (e.g., GitHub profile)