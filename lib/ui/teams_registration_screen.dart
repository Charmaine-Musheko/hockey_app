import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class TeamRegistrationScreen extends StatefulWidget {
  @override
  _TeamRegistrationScreenState createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _coachNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Team'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _teamNameController,
                decoration: InputDecoration(labelText: 'Team Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter team name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _coachNameController,
                decoration: InputDecoration(labelText: 'Coach Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter coach name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contactNumberController,
                decoration: InputDecoration(labelText: 'Contact Number'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Submit'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance.collection('teams').add({
                      'teamName': _teamNameController.text,
                      'coachName': _coachNameController.text,
                      'contactNumber': _contactNumberController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Team Registered Successfully!')),
                    );
                    _teamNameController.clear();
                    _coachNameController.clear();
                    _contactNumberController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
