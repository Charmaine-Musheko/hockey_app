import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get current user
import 'package:intl/intl.dart'; // For date formatting (ensure intl package is in pubspec.yaml)

class UserBookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user's ID
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Should ideally be handled by the Wrapper, but a fallback message is good
      return Scaffold(
        appBar: AppBar(title: Text('My Bookings')),
        body: Center(child: Text('Please sign in to view your bookings.')),
      );
    }

    final String currentUserId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch bookings for the current user, ordered by booking date
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUserId) // Filter by the current user's ID
            .orderBy('bookingDate', descending: true) // Show most recent bookings first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading bookings.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(child: Text('You have no upcoming bookings yet.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              // Optional: Get the event details from the eventId if needed for more info
              // final String eventId = booking['eventId'];

              final Timestamp bookingTimestamp = booking['bookingDate'] ?? Timestamp.now();
              final DateTime bookingDateTime = bookingTimestamp.toDate();
              final formattedBookingDate = DateFormat('yyyy-MM-dd HH:mm').format(bookingDateTime); // Format the date

              final String eventName = booking['eventName'] ?? 'Unnamed Event';
              final String status = booking['status'] ?? 'Confirmed';
              final int numberOfTickets = booking['numberOfTickets'] ?? 1;


              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.event_available), // Icon for booking
                  title: Text(
                    eventName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booked On: $formattedBookingDate'),
                      Text('Status: $status'),
                      Text('Tickets: $numberOfTickets'),
                    ],
                  ),
                  isThreeLine: true,
                  // You might add onTap here to navigate to the Event Detail screen
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => EventDetailScreen(eventId: booking['eventId']),
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
