import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get current user
import 'package:intl/intl.dart'; // For date formatting (ensure intl package is in pubspec.yaml)

class UserMatchBookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user's ID
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Should ideally be handled by the Wrapper, but a fallback message is good
      return Scaffold(
        appBar: AppBar(title: Text('My Match Bookings')),
        body: Center(child: Text('Please sign in to view your match bookings.')),
      );
    }

    final String currentUserId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Match Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch match bookings for the current user, ordered by booking date
        stream: FirebaseFirestore.instance
            .collection('matchBookings') // Query the matchBookings collection
            .where('userId', isEqualTo: currentUserId) // Filter by the current user's ID
            .orderBy('bookingDate', descending: true) // Show most recent bookings first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error loading match bookings: ${snapshot.error}");
            return Center(child: Text('Error loading match bookings.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(child: Text('You have not booked any matches yet.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              // Optional: Get the match details from the matchId if needed for more info
              // final String matchId = booking['matchId'];

              final Timestamp bookingTimestamp = booking['bookingDate'] ?? Timestamp.now();
              final DateTime bookingDateTime = bookingTimestamp.toDate();
              final formattedBookingDate = DateFormat('yyyy-MM-dd HH:mm').format(bookingDateTime); // Format the date

              final String matchName = booking['matchName'] ?? 'Unnamed Match';
              final String status = booking['status'] ?? 'Confirmed';
              // You might add number of attendees if you track that in booking doc

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.sports_hockey), // Icon for match booking
                  title: Text(
                    matchName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booked On: $formattedBookingDate'),
                      Text('Status: $status'),
                      // Text('Attendees: ${booking['attendees'] ?? 1}'), // If you track attendees
                    ],
                  ),
                  isThreeLine: true,
                  // You might add onTap here to navigate to the Match Detail screen
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => MatchDetailScreen(matchId: booking['matchId']),
                  //     ),
                  //   );
                  // },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
