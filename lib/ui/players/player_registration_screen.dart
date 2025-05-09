import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerRegistrationScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  PlayerRegistrationScreen({required this.teamId, required this.teamName});

  @override
  _PlayerRegistrationScreenState createState() => _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState extends State<PlayerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Player (${widget.teamName})')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _playerNameController,
                decoration: InputDecoration(labelText: 'Player Name'),
                validator: (value) => value!.isEmpty ? 'Enter player name' : null,
              ),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(labelText: 'Position'),
                validator: (value) => value!.isEmpty ? 'Enter position' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Submit'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance.collection('players').add({
                      'playerName': _playerNameController.text,
                      'position': _positionController.text,
                      'teamId': widget.teamId,
                      'teamName': widget.teamName,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player Registered!')));
                    _playerNameController.clear();
                    _positionController.clear();
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
