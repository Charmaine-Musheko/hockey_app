import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class GamePredictionsScreen extends StatelessWidget {
  const GamePredictionsScreen({Key? key, required String userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Predictions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch predictions, ordered by predictionDate (most recent first)
        stream: FirebaseFirestore.instance
            .collection('predictions')
            .orderBy('predictionDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Error loading predictions: ${snapshot.error}");
            return const Center(child: Text('Error loading predictions.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final predictions = snapshot.data!.docs;

          if (predictions.isEmpty) {
            return const Center(child: Text('No predictions available yet.'));
          }

          return ListView.builder(
            itemCount: predictions.length,
            itemBuilder: (context, index) {
              final prediction = predictions[index].data() as Map<String, dynamic>;
              final String userId = prediction['userId'] ?? '';
              final String homeTeamName = prediction['homeTeamName'] ?? 'Home Team';
              final String awayTeamName = prediction['awayTeamName'] ?? 'Away Team';
              final int homeScorePrediction = prediction['homeScorePrediction'] ?? 0;
              final int awayScorePrediction = prediction['awayScorePrediction'] ?? 0;

              final Timestamp predictionTimestamp = prediction['predictionDate'] ?? Timestamp.now();
              final DateTime predictionDateTime = predictionTimestamp.toDate();
              final formattedPredictionDate = DateFormat('dd MMM yyyy, HH:mm').format(predictionDateTime);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$homeTeamName vs $awayTeamName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Predicted Score: $homeScorePrediction - $awayScorePrediction',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Predicted On: $formattedPredictionDate',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      // Fetch and display the user's name who made the prediction
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const Text('Predicted by: Loading...', style: TextStyle(fontSize: 14, color: Colors.grey));
                          }
                          if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                            return const Text('Predicted by: Unknown User', style: TextStyle(fontSize: 14, color: Colors.grey));
                          }
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          final String userName = userData['firstName'] ?? userData['email'] ?? 'Unknown User';
                          return Text(
                            'Predicted by: $userName',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
