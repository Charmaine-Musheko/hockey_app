import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class NewsDetailScreen extends StatelessWidget {
  final String newsId; // The ID of the news item to display

  const NewsDetailScreen({Key? key, required this.newsId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Details'), // Will update with news title once loaded
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch the specific news document from Firestore
        future: FirebaseFirestore.instance.collection('news').doc(newsId).get(),
        builder: (context, snapshot) {
          // Show loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            print("Error fetching news data: ${snapshot.error}");
            return Center(child: Text('Error loading news details.'));
          }

          // Handle case where document doesn't exist
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('News item not found.'));
          }

          // News data is loaded
          final newsData = snapshot.data!.data() as Map<String, dynamic>;
          final title = newsData['title'] ?? 'No Title';
          final content = newsData['content'] ?? 'No content available.';
          final String? imageUrl = newsData['imageUrl']; // Get the image URL

          final Timestamp publishTimestamp = newsData['publishDate'] ?? Timestamp.now();
          final DateTime publishDateTime = publishTimestamp.toDate();
          final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(publishDateTime);


          // Update AppBar title once data is loaded (Note for StatelessWidget)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Consider making this a StatefulWidget for smoother title update
          });


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display image if imageUrl exists
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  ClipRRect( // Clip the image with rounded corners
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity, // Make image fill width
                      height: 200, // Set a fixed height for consistency
                      fit: BoxFit.cover, // Cover the area, cropping if necessary
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600])),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                Text(
                  title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Published: $formattedDate',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Text(
                  content,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
