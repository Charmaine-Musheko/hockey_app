import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get user data
import 'add_news.dart'; // Import the Add News screen

// Update NewsListScreen to accept the userId
class NewsListScreen extends StatelessWidget {
  final String userId; // Accept the user ID

  const NewsListScreen({Key? key, required this.userId}) : super(key: key); // Require userId

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService(); // Get AuthService instance

    return Scaffold(
      appBar: AppBar(
        title: Text('News & Announcements'),
        // The Add button will be a FloatingActionButton defined in the body's FutureBuilder
      ),
      // Use a FutureBuilder to fetch the current user's role and build the body and FAB
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _auth.getUserData(userId), // Fetch user data using the passed userId
        builder: (context, userSnapshot) {
          // Show loading indicator while fetching user data
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle error or missing user data
          if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
            print("Error fetching user data in NewsListScreen: ${userSnapshot.error}");
            // You might still want to show the news list even if user data fails
            // For now, let's show an error message, but you could adjust this
            // You can also return an empty list or a list with an error message card
            return Center(child: Text('Error loading user data for permissions.'));
          }

          // User data fetched, get the role
          final userData = userSnapshot.data!;
          final userRole = userData['role'] ?? 'Fan'; // Default to 'Fan'

          // Determine if the user is allowed to add news
          final bool canAddNews = userRole == 'Coach' || userRole == 'Admin';

          // Now, build the main content (the news list) using a StreamBuilder
          // and include the FloatingActionButton here in the same scope
          return Scaffold( // Use an inner Scaffold to place the FAB
            body: StreamBuilder<QuerySnapshot>(
              // Fetch news items, ordered by publish date (most recent first)
              stream: FirebaseFirestore.instance
                  .collection('news')
                  .orderBy('publishDate', descending: true) // Order by most recent news
                  .snapshots(),
              builder: (context, newsSnapshot) {
                if (newsSnapshot.hasError) {
                  return Center(child: Text('Error loading news.'));
                }

                if (newsSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final newsItems = newsSnapshot.data!.docs;

                if (newsItems.isEmpty) {
                  return Center(child: Text('No news or announcements available yet.'));
                }

                return ListView.builder(
                  itemCount: newsItems.length,
                  itemBuilder: (context, index) {
                    final news = newsItems[index].data() as Map<String, dynamic>;

                    final Timestamp publishTimestamp = news['publishDate'] ?? Timestamp.now();
                    final DateTime publishDateTime = publishTimestamp.toDate();
                    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(publishDateTime); // Format the date

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        // Optional: Display an image if imageUrl exists
                        // leading: news['imageUrl'] != null && news['imageUrl'].isNotEmpty
                        //     ? Image.network(news['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                        //     : null,
                        title: Text(
                          news['title'] ?? 'No Title',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(news['content'] ?? 'No content available.', maxLines: 3, overflow: TextOverflow.ellipsis), // Show snippet
                            SizedBox(height: 4),
                            Text('Published: $formattedDate', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        isThreeLine: true, // Allows the subtitle to use more lines
                        // You can add onTap here to navigate to a full News Detail screen later
                        // onTap: () {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => NewsDetailScreen(newsId: newsItems[index].id),
                        //     ),
                        //   );
                        // },
                      ),
                    );
                  },
                );
              },
            ),
            // Conditionally show the FloatingActionButton for adding news inside this inner Scaffold
            floatingActionButton: canAddNews
                ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddNewsScreen()),
                );
              },
              child: Icon(Icons.add),
              tooltip: 'Add New Announcement',
            )
                : null, // Hide the FAB if the user cannot add news
          );
        },
      ),
      // The outer Scaffold does not have a floatingActionButton here anymore
    );
  }
}
