import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hockey_union_app/ui/players/manage_players_screen.dart';
import 'package:hockey_union_app/ui/predictions/game_predictions.dart';
import 'package:hockey_union_app/ui/teams/team_list_screen.dart';
import 'package:hockey_union_app/ui/teams/teams_registration_screen.dart';
import 'package:hockey_union_app/ui/events/events_list.dart';
import 'package:hockey_union_app/ui/matches/add_edit_match_screen.dart';
import 'package:hockey_union_app/ui/news/news_list_screen.dart';
import 'package:hockey_union_app/ui/booking/user_booking_screen.dart';
import 'package:hockey_union_app/ui/players/player_profile_screen.dart';
import 'package:hockey_union_app/utils/app_colors.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import 'chat/chat_screen.dart';
import 'matches/match_scheduler_screen.dart'; // Import the new ChatScreen

class HomeScreen extends StatelessWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        toolbarHeight: 0,
        // The menu icon is positioned in the Stack, not in the AppBar
        // Add Sign Out button to AppBar actions
        actions: [
          TextButton.icon(
            icon: Icon(Icons.logout, color: AppColors.white),
            label: Text('Sign Out', style: TextStyle(color: AppColors.white)),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.primaryGreen,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get().then((doc) => doc.data()),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
            }
            if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
              return Center(child: Text('Error loading user data.', style: TextStyle(color: AppColors.white)));
            }

            final userData = userSnapshot.data!;
            final userRole = userData['role'] ?? 'Fan';
            final String userName = userData['firstName'] ?? userData['email'] ?? 'User';


            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.accentOrange.withOpacity(0.5),
                        child: Icon(Icons.person, size: 40, color: AppColors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Welcome, $userName',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Role: $userRole',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // --- Drawer Items (Conditional based on Role) ---
                ListTile(
                  leading: Icon(Icons.home, color: AppColors.white),
                  title: Text('Home', style: TextStyle(color: AppColors.white)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    // Already on Home, just close drawer
                  },
                ),
                if (userRole == 'Player')
                ListTile(
                  leading: Icon(Icons.leaderboard, color: AppColors.white),
                  title: Text('My Player Profile (Stats)', style: TextStyle(color: AppColors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlayerProfileScreen(playerId: userId)),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.emoji_events, color: AppColors.white),
                  title: Text('Events', style: TextStyle(color: AppColors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventListScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat, color: AppColors.white),
                  title: Text('Chat', style: TextStyle(color: AppColors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatScreen(userId: userId)),
                    );
                  },
                ),
                Divider(color: AppColors.white.withOpacity(0.5)),

                // Admin/Coach specific functions
                if (userRole == 'Coach' || userRole == 'Admin') ...[
                  ListTile(
                    leading: Icon(Icons.group_add, color: AppColors.white),
                    title: Text('Register a Team', style: TextStyle(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TeamRegistrationScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.sports_baseball, color: AppColors.white),
                    title: Text('Manage Players', style: TextStyle(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ManagePlayersScreen(userId: userId)),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.add_box, color: AppColors.white),
                    title: Text('Add New Match', style: TextStyle(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddEditMatchScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.newspaper, color: AppColors.white),
                    title: Text('News & Announcements', style: TextStyle(color: AppColors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NewsListScreen(userId: userId)),
                      );
                    },
                  ),
                  Divider(color: AppColors.white.withOpacity(0.5)),
                ],

                // General functions available to all roles
                ListTile(
                  leading: Icon(Icons.groups, color: AppColors.white),
                  title: Text('View Teams', style: TextStyle(color: AppColors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TeamListScreen(userId: userId)),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_today, color: AppColors.white),
                  title: Text('Match Schedule', style: TextStyle(color: AppColors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MatchScheduleScreen(userId: userId)),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.receipt_long, color: AppColors.white),
                  title: Text('My Bookings', style: TextStyle(color: AppColors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserMatchBookingsScreen()),
                    );
                  },
                ),

                Divider(color: AppColors.white.withOpacity(0.5)),
                // Logout is now in AppBar, but keeping it here as well for consistency if user prefers drawer
                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.accentOrange),
                  title: Text('Logout', style: TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _auth.signOut();
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get().then((doc) => doc.data()),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
          }
          if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
            print("Error fetching user data in HomeScreen: ${userSnapshot.error}");
            return Center(child: Text('Error loading user data.', style: TextStyle(color: AppColors.white)));
          }

          final userData = userSnapshot.data!;
          final userRole = userData['role'] ?? 'Fan';
          final String firstName = userData['firstName'] ?? 'User';

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('players').doc(userId).get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                            }
                            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (userRole == 'Player') ...[
                                    Text(
                                      '$firstName\'s Stats',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Stats: Yet to update',
                                      style: TextStyle(fontSize: 16, color: AppColors.darkText),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Welcome, $firstName!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Enjoy the Hockey Union App!',
                                      style: TextStyle(fontSize: 16, color: AppColors.darkText),
                                    ),
                                  ],
                                ],
                              );
                            }

                            final userData = snapshot.data!.data() as Map<String, dynamic>;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Conditional display for SAHA/Rank/Points
                                if (userRole == 'Player') ...[
                                  Text(
                                    '$firstName\'s Stats', // Changed from 'SAHA' to player's name
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${userData['assists'] ?? 'N/A'} Assists', // Placeholder for rank
                                        style: TextStyle(fontSize: 16, color: AppColors.darkText),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        '${userData['goals'] ?? 'N/A'} Goals', // Placeholder for points
                                        style: TextStyle(fontSize: 16, color: AppColors.darkText),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  // For non-players, just a welcome message
                                  Text(
                                    'Welcome, ${firstName}!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Enjoy the Hockey Union App!',
                                    style: TextStyle(fontSize: 16, color: AppColors.darkText),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Matches',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MatchScheduleScreen(userId: userId)),
                                );
                              },
                              child: Text('Show all', style: TextStyle(color: AppColors.accentOrange)),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('matches')
                              .orderBy('matchDate', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, matchSnapshot) {
                            if (matchSnapshot.hasError) {
                              return Text('Error loading match data.', style: TextStyle(color: Colors.red));
                            }
                            if (matchSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
                            }
                            if (matchSnapshot.data!.docs.isEmpty) {
                              return Text('No upcoming matches.', style: TextStyle(color: AppColors.darkText));
                            }

                            final match = matchSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            final matchDocId = matchSnapshot.data!.docs.first.id;

                            final Timestamp matchTimestamp = match['matchDate'] ?? Timestamp.now();
                            final DateTime matchDateTime = matchTimestamp.toDate();
                            final formattedDate = DateFormat('dd MMMMEEEE, HH:mm').format(matchDateTime);

                            final String homeTeamName = match['homeTeamName'] ?? 'Home Team';
                            final String awayTeamName = match['awayTeamName'] ?? 'Away Team';
                            final String status = match['status'] ?? 'Scheduled';

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildTeamDisplay(homeTeamName, 'assets/images/flag_placeholder.png'),
                                        Text(
                                          'vs',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                        ),
                                        _buildTeamDisplay(awayTeamName, 'assets/images/flag_placeholder.png', isRightAligned: true),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    Center(
                                      child: Text(
                                        '${match['location'] ?? 'Venue TBD'}',
                                        style: TextStyle(fontSize: 14, color: AppColors.darkText),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showPredictGameDialog(context, matchDocId, homeTeamName, awayTeamName, userId);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accentOrange,
                                          foregroundColor: AppColors.white,
                                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                        ),
                                        child: Text('PREDICT GAME'),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Center(
                                      child: Text(
                                        'Presented by NHU',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Official news',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => NewsListScreen(userId: userId)),
                                );
                              },
                              child: Text('Show all', style: TextStyle(color: AppColors.accentOrange)),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('news')
                              .orderBy('publishDate', descending: true)
                              .limit(2)
                              .snapshots(),
                          builder: (context, newsSnapshot) {
                            if (newsSnapshot.hasError) {
                              return Text('Error loading news.', style: TextStyle(color: Colors.red));
                            }
                            if (newsSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
                            }
                            if (newsSnapshot.data!.docs.isEmpty) {
                              return Text('No news available.', style: TextStyle(color: AppColors.darkText));
                            }

                            final newsItems = newsSnapshot.data!.docs;

                            return Column(
                              children: newsItems.map((doc) {
                                final news = doc.data() as Map<String, dynamic>;
                                final Timestamp publishTimestamp = news['publishDate'] ?? Timestamp.now();
                                final DateTime publishDateTime = publishTimestamp.toDate();
                                final formattedNewsDate = DateFormat('dd MMMMEEEE').format(publishDateTime);

                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryGreen.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Icon(Icons.image, size: 40, color: AppColors.secondaryGreen),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                news['title'] ?? 'No Title',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                formattedNewsDate,
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                news['content'] ?? 'No content available.',
                                                style: TextStyle(fontSize: 14, color: AppColors.darkText),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Builder( // Added Builder here
                  builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.menu, size: 30, color: AppColors.primaryGreen),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Builder( // Wrap BottomNavigationBar with Builder
          builder: (context) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                child: BottomNavigationBar(
                  backgroundColor: AppColors.primaryGreen,
                  selectedItemColor: AppColors.accentOrange,
                  unselectedItemColor: AppColors.white.withOpacity(0.7),
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home, size: 28),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.leaderboard, size: 28),
                      label: 'Stats',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat, size: 28),
                      label: 'Chat',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.menu, size: 28),
                      label: 'More',
                    ),
                  ],
                  currentIndex: 0,
                  onTap: (index) {
                    print('Tapped item: $index');
                    switch (index) {
                      case 0:
                        break;
                      case 1:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GamePredictionsScreen(userId: userId)),//here charmaine
                        );
                        break;
                      case 2:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatScreen(userId: userId)),
                        );
                        break;
                      case 3: // More tab (opens drawer)
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserMatchBookingsScreen()),
                        );
                        break;
                    }
                  },
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildTeamDisplay(String teamName, String flagAssetPath, {bool isRightAligned = false}) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(child: Icon(Icons.flag, size: 30, color: Colors.grey[600])),
        ),
        SizedBox(height: 8),
        Text(
          teamName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
          textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }

  Future<void> _showPredictGameDialog(BuildContext context, String matchId, String homeTeamName, String awayTeamName, String userId) async {
    final TextEditingController homeScoreController = TextEditingController();
    final TextEditingController awayScoreController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text('Predict Score for\n$homeTeamName vs $awayTeamName', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryGreen)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: homeScoreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '$homeTeamName Score',
                      prefixIcon: Icon(Icons.sports_hockey, color: AppColors.primaryGreen),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter score';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: awayScoreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '$awayTeamName Score',
                      prefixIcon: Icon(Icons.sports_hockey, color: AppColors.primaryGreen),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter score';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: AppColors.darkText)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: Text('Submit Prediction'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final int homeScore = int.parse(homeScoreController.text);
                  final int awayScore = int.parse(awayScoreController.text);

                  try {
                    await FirebaseFirestore.instance.collection('predictions').add({
                      'userId': userId,
                      'matchId': matchId,
                      'homeScorePrediction': homeScore,
                      'awayScorePrediction': awayScore,
                      'predictionDate': FieldValue.serverTimestamp(),
                      'homeTeamName': homeTeamName,
                      'awayTeamName': awayTeamName,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Prediction submitted successfully!')),
                    );
                    Navigator.of(dialogContext).pop();
                  } catch (e) {
                    print("Error submitting prediction: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit prediction.')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}