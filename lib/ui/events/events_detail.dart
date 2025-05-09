import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:hockey_union_app/services/auth_service.dart'; // Import AuthService to get current user ID

class EventDetailScreen extends StatelessWidget {
  final String eventId; // The ID of the event to display

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  // Function to handle the booking process
  Future<void> _handleBooking(BuildContext context, String eventName, double ticketPrice, int availableTickets, String eventId) async {
    final AuthService _auth = AuthService();
    final currentUser = _auth.getCurrentUser(); // Get the currently logged-in user

    if (currentUser == null) {
      // User is not logged in, prompt them to log in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to book a spot.')),
      );
      // You might want to navigate to the AuthScreen here
      // Navigator.pushReplacementNamed(context, '/auth');
      return;
    }

    // Check if tickets are available (if totalTickets was specified)
    if (availableTickets != -1 && availableTickets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sorry, this event is sold out.')),
      );
      return;
    }

    // --- Implement the booking transaction ---
    // Use a Firestore transaction to ensure atomicity when updating availableTickets
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    final bookingsRef = FirebaseFirestore.instance.collection('bookings');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the latest event document within the transaction
        DocumentSnapshot latestEventDoc = await transaction.get(eventRef);

        if (!latestEventDoc.exists) {
          throw Exception("Event does not exist!"); // Should not happen if we reached this screen
        }

        // Get the current available tickets
        int currentAvailableTickets = latestEventDoc['availableTickets'] ?? (latestEventDoc['totalTickets'] ?? -1);

        // Re-check availability within the transaction
        if (currentAvailableTickets != -1 && currentAvailableTickets <= 0) {
          throw Exception("Event is now sold out."); // Handle race condition
        }

        // Decrement available tickets (if totalTickets was specified)
        if (currentAvailableTickets != -1) {
          transaction.update(eventRef, {'availableTickets': currentAvailableTickets - 1});
        }

        // Create a new booking document
        transaction.set(bookingsRef.doc(), { // Use doc() to let Firestore generate an ID
          'userId': currentUser.uid,
          'eventId': eventId,
          'bookingDate': FieldValue.serverTimestamp(),
          'status': 'Confirmed', // Default status
          'numberOfTickets': 1, // Assuming 1 ticket per booking for now
          'userName': currentUser.email, // Or fetch from user doc if you stored name
          'eventName': eventName, // Store event name for easier query
        });
      });

      // Transaction successful
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully booked your spot for $eventName!')),
      );

    } catch (e) {
      print("Error during booking transaction: $e");
      String errorMessage = 'Failed to book spot.';
      if (e.toString().contains("sold out")) {
        errorMessage = 'Sorry, this event is now sold out.';
      } else if (e.toString().contains("Event does not exist")) {
        errorMessage = 'Error: Event not found.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'), // Will update with event name once loaded
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific event document from Firestore
        future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
        builder: (context, snapshot) {
          // Show loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            print("Error fetching event data: ${snapshot.error}");
            return Center(child: Text('Error loading event details.'));
          }

          // Handle case where document doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Event not found.'));
          }

          // Event data is loaded
          final eventData = snapshot.data!.data() as Map<String, dynamic>;
          final eventName = eventData['name'] ?? 'Unnamed Event';
          final description = eventData['description'] ?? 'No description provided.';
          final location = eventData['location'] ?? 'TBD';
          final type = eventData['type'] ?? 'Event';

          final Timestamp startTimestamp = eventData['startDate'] ?? Timestamp.now();
          final DateTime startDateTime = startTimestamp.toDate();
          final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(startDateTime);

          String endDateDisplay = '';
          if (eventData['endDate'] != null) {
            final Timestamp endTimestamp = eventData['endDate'];
            final DateTime endDateTime = endTimestamp.toDate();
            endDateDisplay = ' - ${DateFormat('yyyy-MM-dd HH:mm').format(endDateTime)}';
          }

          String ticketInfo = '';
          final double ticketPrice = eventData['ticketPrice'] ?? -1.0;
          final int availableTickets = eventData['availableTickets'] ?? -1;
          final int totalTickets = eventData['totalTickets'] ?? -1;

          bool isSoldOut = false;
          if (ticketPrice >= 0) {
            ticketInfo += 'Price: ${ticketPrice == 0 ? 'Free' : '\$' + ticketPrice.toStringAsFixed(2)}';
            if (totalTickets >= 0) {
              ticketInfo += ' | Tickets: ${availableTickets >= 0 ? availableTickets : 'N/A'}/${totalTickets}';
              if (availableTickets != -1 && availableTickets <= 0) {
                isSoldOut = true; // Mark as sold out
              }
            }
          }

          // Optional: Get image URL
          final String? imageUrl = eventData['imageUrl'];

          // Determine if booking button should be enabled
          final bool canBook = !isSoldOut; // Can book if not sold out (and implicitly if ticketPrice >= 0)


          // Update AppBar title once data is loaded (Note for StatelessWidget)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Consider making this a StatefulWidget for smoother title update
          });


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optional: Display event image
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  Image.network(
                    imageUrl,
                    width: double.infinity, // Make image fill width
                    height: 200, // Set a height
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Center(child: Text('Image not available')),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                Text(
                  eventName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Date: $formattedDate$endDateDisplay', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Location: $location', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Type: $type', style: TextStyle(fontSize: 18)),
                if (ticketInfo.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(ticketInfo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],

                SizedBox(height: 24),
                Text(
                  'Description:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(description, style: TextStyle(fontSize: 16)),

                SizedBox(height: 24),
                // Booking/Registration button
                ElevatedButton(
                  // Disable button if sold out
                  onPressed: canBook
                      ? () => _handleBooking(context, eventName, ticketPrice, availableTickets, eventId)
                      : null, // Disable if canBook is false
                  child: Text(isSoldOut ? 'Sold Out' : 'Book Spot / Get Tickets'), // Change button text if sold out
                ),
                if (isSoldOut) // Add a message below the button if sold out
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Check back later for potential cancellations.', style: TextStyle(fontSize: 14, color: Colors.red)),
                  ),

              ],
            ),
          );
        },
      ),
    );
  }
}
