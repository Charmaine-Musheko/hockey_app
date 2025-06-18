# Namibia Hockey Union Mobile Application

## Project Overview
This mobile application was developed for the Namibia Hockey Union using **Flutter** and **Firebase**. It provides a comprehensive platform for managing hockey-related information such as teams, players, match schedules, events, news, and user-specific functionalities based on roles.

---

## Features

### User Authentication
- Secure email and password-based registration and login.

### Role-Based Access Control
- Roles: Fan, Player, Coach, Admin
- Each role has access to specific features and content.

### Team Management
- View all registered teams.
- Register new teams (Coach/Admin).

### Player Management
- Register new players (Coach/Admin).
- Manage player profiles including stats (goals, assists, games played) and achievements.
- Link player profiles to user accounts.

### Match Management
- View upcoming match schedule.
- Add and edit match details (Coach/Admin).
- Display scores for completed/in-progress matches.

### Event Management
- View upcoming events.
- View event details (date, location, description, ticket info).
- Add and edit event details (Coach/Admin).

### Booking System
- Book spots for scheduled matches (authenticated users).
- Book tickets/spots for events with basic ticket availability tracking.
- View list of user's bookings.

### News and Announcements
- View feed of news and announcements.
- Publish news items (Coach/Admin).

### Player Profile
- Dedicated screen for players to view personal stats and achievements.

### Additional Features
- Splash screen on app startup.
- Sleek UI with navy blue color contrast.

---

## Technologies Used

- **Framework:** Flutter (vX.Y.Z)  
- **Backend:** Firebase  
  - Firebase Authentication  
  - Firestore (NoSQL database)  
  - Firebase Cloud Messaging (FCM) – initial push notifications setup  

### Key Packages
- `cloud_firestore`  
- `firebase_auth`  
- `firebase_core`  
- `firebase_messaging`  
- `intl`  
- `flutter_local_notifications`  
- *(Add any other significant packages you used)*

---

## Setup and Installation

### Clone the Repository
```bash
git clone <repository_url>
cd <repository_name>


