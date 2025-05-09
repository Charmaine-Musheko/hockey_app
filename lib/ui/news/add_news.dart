import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewsScreen extends StatefulWidget {
  @override
  _AddNewsScreenState createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = false; // To show a loading indicator

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Function to save the news item
  Future<void> _saveNews() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Prepare data map for the news item
      Map<String, dynamic> newsData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'publishDate': FieldValue.serverTimestamp(), // Use server timestamp for consistent date
        // Optional: Add authorId if you want to link news to a user
        // 'authorId': 'current_user_id', // You would get the current user's ID here
      };

      try {
        // Add a new document to the 'news' collection
        await FirebaseFirestore.instance.collection('news').add(newsData);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('News item published successfully!')));

        // Clear form fields after successful save
        _titleController.clear();
        _contentController.clear();

        // Optionally navigate back after saving
        // Navigator.pop(context);

      } catch (e) {
        print("Error publishing news: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish news.')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Publish New Announcement'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrolling
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (val) => val!.isEmpty ? 'Enter a title' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Content'),
                validator: (val) => val!.isEmpty ? 'Enter content for the announcement' : null,
                maxLines: 8, // Allow multiple lines for content
                keyboardType: TextInputType.multiline,
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                child: Text('Publish Announcement'),
                onPressed: _saveNews,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
