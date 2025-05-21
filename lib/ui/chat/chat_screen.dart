import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hockey_union_app/utils/app_colors.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _currentUser;
  String? _currentUserName; // To store user's first name for chat display

  @override
  void initState() {
    super.initState();
    _currentUser = _firebaseAuth.currentUser;
    _fetchUserName(); // Fetch user's first name
  }

  Future<void> _fetchUserName() async {
    if (_currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserName = userDoc.data()?['firstName'] ?? _currentUser!.email?.split('@')[0];
        });
      } else {
        setState(() {
          _currentUserName = _currentUser!.email?.split('@')[0];
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to send messages.')),
      );
      return;
    }

    try {
      await _firestore.collection('chats').add({
        'senderId': _currentUser!.uid,
        'senderName': _currentUserName ?? _currentUser!.email,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        title: Text('Fan Chat', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('chats').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading messages.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No messages yet. Start the conversation!'));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true, // Show latest messages at the bottom
                    padding: const EdgeInsets.all(16.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageData = messages[index].data() as Map<String, dynamic>;
                      final String senderId = messageData['senderId'];
                      final String senderName = messageData['senderName'] ?? 'Anonymous';
                      final String messageText = messageData['message'];
                      final Timestamp? timestamp = messageData['timestamp'];
                      final DateTime messageTime = timestamp?.toDate() ?? DateTime.now();
                      final formattedTime = DateFormat('HH:mm').format(messageTime);

                      final bool isMe = senderId == _currentUser?.uid;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.accentOrange : AppColors.primaryGreen.withOpacity(0.8),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isMe ? 15 : 0),
                              topRight: Radius.circular(isMe ? 0 : 15),
                              bottomLeft: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMe ? 'You' : senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                messageText,
                                style: TextStyle(color: AppColors.white, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  color: AppColors.white.withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: AppColors.accentOrange,
                  mini: true,
                  child: Icon(Icons.send, color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}