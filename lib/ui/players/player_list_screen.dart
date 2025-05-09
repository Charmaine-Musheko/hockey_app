import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerListScreen extends StatelessWidget {
  final String teamId;
  final String teamName;

  const PlayerListScreen({Key? key, required this.teamId, required this.teamName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Players - $teamName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .collection('players')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading players.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final players = snapshot.data!.docs;

          if (players.isEmpty) {
            return Center(child: Text('No players registered for this team.'));
          }

          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index].data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.sports_hockey),
                  title: Text(player['name'] ?? 'Unknown Player'),
                  subtitle: Text('Age: ${player['age'] ?? 'N/A'}\nPosition: ${player['position'] ?? 'N/A'}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
