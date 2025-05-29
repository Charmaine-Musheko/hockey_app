import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class RoleApprovalScreen extends StatelessWidget {
  const RoleApprovalScreen({Key? key}) : super(key: key);

  // Function to approve a role request
  Future<void> _approveRequest(BuildContext context, String requestId, String userId, String newRole) async {
    try {
      // Update the user's role
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });
      // Delete the role request
      await FirebaseFirestore.instance.collection('roleRequests').doc(requestId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role for user $userId approved to $newRole!')),
      );
    } catch (e) {
      print("Error approving request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve request.')),
      );
    }
  }

  // Function to reject a role request
  Future<void> _rejectRequest(BuildContext context, String requestId, String userId) async {
    try {
      // Simply delete the role request (or update status to 'Rejected')
      await FirebaseFirestore.instance.collection('roleRequests').doc(requestId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role request for user $userId rejected.')),
      );
    } catch (e) {
      print("Error rejecting request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Role Approval Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('roleRequests')
            .where('status', isEqualTo: 'Pending') // Only show pending requests
            .orderBy('requestDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading requests.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(child: Text('No pending role approval requests.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;
              final userId = request['userId'] ?? 'N/A';
              final email = request['email'] ?? 'N/A';
              final firstName = request['firstName'] ?? '';
              final lastName = request['lastName'] ?? '';
              final requestedRole = request['requestedRole'] ?? 'N/A';
              final roleReason = request['roleReason'] ?? 'No reason provided.';
              final Timestamp requestTimestamp = request['requestDate'] ?? Timestamp.now();
              final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(requestTimestamp.toDate());

              String displayName = '';
              if (firstName.isNotEmpty && lastName.isNotEmpty) {
                displayName = '$firstName $lastName';
              } else {
                displayName = email;
              }


              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User: $displayName',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text('Requested Role: $requestedRole', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Reason: $roleReason', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Requested On: $formattedDate', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _approveRequest(context, requestId, userId, requestedRole),
                            child: Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                          SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _rejectRequest(context, requestId, userId),
                            child: Text('Reject'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
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
