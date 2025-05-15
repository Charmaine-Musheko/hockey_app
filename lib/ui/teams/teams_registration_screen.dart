import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get current user


class TeamRegistrationScreen extends StatefulWidget {
  @override
  _TeamRegistrationScreenState createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _coachNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();

  bool _isLoading = false; // To show a loading indicator

  @override
  void dispose() {
    _teamNameController.dispose();
    _coachNameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  // Function to save the team and associate it with the current user
  Future<void> _saveTeam() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Get the currently logged-in user
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // This case should ideally be prevented by role-based access on the button,
        // but it's good practice to handle it.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must be logged in to register a team.')));
        setState(() { _isLoading = false; });
        return;
      }

      // Prepare data map for the new team
      Map<String, dynamic> teamData = {
        'teamName': _teamNameController.text.trim(),
        'coachName': _coachNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp for ordering
        'registeredBy': currentUser.uid, // Optional: Store who registered the team
      };

      try {
        // Add the new team document to the 'teams' collection
        DocumentReference teamDocRef = await FirebaseFirestore.instance.collection('teams').add(teamData);

        // Get the ID of the newly created team document
        String newTeamId = teamDocRef.id;

        // Now, update the current user's document to associate this team ID
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'teamId': newTeamId, // Add or update the teamId field
          // You might also want to store the team name here for easier access, or just rely on teamId
          // 'teamName': _teamNameController.text.trim(),
        });


        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Team registered and associated with your account!')));

        // Clear form fields after successful save
        _teamNameController.clear();
        _coachNameController.clear();
        _contactNumberController.clear();

        // Optionally navigate back after saving
        // Navigator.pop(context);

      } catch (e) {
        print("Error saving team or associating user: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to register team or associate with account.')));
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
        title: Text('Register New Team'),
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
                controller: _teamNameController,
                decoration: InputDecoration(labelText: 'Team Name'),
                validator: (val) => val!.isEmpty ? 'Enter team name' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _coachNameController,
                decoration: InputDecoration(labelText: 'Coach Name'),
                validator: (val) => val!.isEmpty ? 'Enter coach name' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _contactNumberController,
                decoration: InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone, // Suggest phone number keyboard
                validator: (val) => val!.isEmpty ? 'Enter contact number' : null,
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                child: Text('Register Team'),
                onPressed: _saveTeam,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
