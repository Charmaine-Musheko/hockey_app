import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting (ensure intl package is in pubspec.yaml)
// Import EventDetailScreen later
// import 'package:hockey_union_app/ui/events/event_detail_screen.dart';

class EventListScreen extends StatelessWidget {
  // We might pass userId here later if we need role-based actions on this screen
  // final String userId;
  // const EventListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upcoming Events'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch events, ordered by start date (upcoming first)
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('startDate', descending: false) // Order by upcoming date
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading events.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs;

          if (events.isEmpty) {
            return Center(child: Text('No upcoming events scheduled yet.'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              final eventDocId = events[index].id; // Get the document ID

              final Timestamp startTimestamp = event['startDate'] ?? Timestamp.now();
              final DateTime startDateTime = startTimestamp.toDate();
              final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(startDateTime); // Format the date

              // Optional: Format end date if it exists
              String endDateDisplay = '';
              if (event['endDate'] != null) {
                final Timestamp endTimestamp = event['endDate'];
                final DateTime endDateTime = endTimestamp.toDate();
                endDateDisplay = ' - ${DateFormat('yyyy-MM-dd HH:mm').format(endDateTime)}';
              }

              // Display ticket info if available
              String ticketInfo = '';
              final double ticketPrice = event['ticketPrice'] ?? -1.0; // Use -1 to indicate not specified
              final int availableTickets = event['availableTickets'] ?? -1; // Use -1 to indicate not specified
              final int totalTickets = event['totalTickets'] ?? -1; // Use -1 to indicate not specified

              if (ticketPrice >= 0) {
                ticketInfo += 'Price: ${ticketPrice == 0 ? 'Free' : '\$' + ticketPrice.toStringAsFixed(2)}';
                if (totalTickets >= 0) {
                  ticketInfo += ' | Tickets: ${availableTickets >= 0 ? availableTickets : 'N/A'}/${totalTickets}';
                }
              }


              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  // Optional: Display event image if imageUrl exists
                  // leading: event['imageUrl'] != null && event['imageUrl'].isNotEmpty
                  //     ? Image.network(event['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                  //     : null,
                  title: Text(
                    event['name'] ?? 'Unnamed Event',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: $formattedDate$endDateDisplay'),
                      Text('Location: ${event['location'] ?? 'TBD'}'),
                      Text('Type: ${event['type'] ?? 'Event'}'),
                      if (ticketInfo.isNotEmpty) Text(ticketInfo), // Show ticket info if available
                      SizedBox(height: 4),
                      Text(event['description'] ?? 'No description provided.', maxLines: 2, overflow: TextOverflow.ellipsis), // Show snippet
                    ],
                  ),
                  isThreeLine: true, // Allows subtitle to use more lines
                  // Add onTap here to navigate to an Event Detail screen later
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => EventDetailScreen(eventId: eventDocId),
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
