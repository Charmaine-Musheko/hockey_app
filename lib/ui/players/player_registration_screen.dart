import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlayerRegistrationScreen extends StatefulWidget {
  final String teamId;
  final String teamName;
  // Optional: Pass playerId if editing an existing player
  final String? playerId;

  // Updated constructor to accept optional playerId
  PlayerRegistrationScreen({
    Key? key,
    required this.teamId,
    required this.teamName,
    this.playerId, // Make playerId optional
  }) : super(key: key);

  @override
  _PlayerRegistrationScreenState createState() => _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState extends State<PlayerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  // Add controllers for stats fields
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _assistsController = TextEditingController();
  final TextEditingController _gamesPlayedController = TextEditingController();
  // Add controller for achievements (using a single text field for simplicity initially)
  final TextEditingController _achievementsController = TextEditingController();


  bool _isLoading = false; // To show a loading indicator
  bool _isEditing = false; // To know if we are editing or adding

  // Load existing player data if playerId is provided
  @override
  void initState() {
    super.initState();
    if (widget.playerId != null) {
      _isEditing = true; // Set editing mode
      _loadPlayerData(widget.playerId!);
    }
  }

  // Dispose controllers
  @override
  void dispose() {
    _playerNameController.dispose();
    _positionController.dispose();
    _goalsController.dispose();
    _assistsController.dispose();
    _gamesPlayedController.dispose();
    _achievementsController.dispose();
    super.dispose();
  }

  // Function to load data for editing
  Future<void> _loadPlayerData(String playerId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('players').doc(playerId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _playerNameController.text = data['playerName'] ?? '';
        _positionController.text = data['position'] ?? '';
        // Load stats, defaulting to '0' if null or not present
        _goalsController.text = (data['goals']?.toString() ?? '0');
        _assistsController.text = (data['assists']?.toString() ?? '0');
        _gamesPlayedController.text = (data['gamesPlayed']?.toString() ?? '0');
        // Load achievements (assuming they were stored as a List<String> or similar)
        // For simplicity with a single text field, join them with a separator
        final List<dynamic> achievementsList = data['achievements'] is List ? data['achievements'] : [];
        _achievementsController.text = achievementsList.join(', '); // Join achievements with comma and space


      } else {
        // Handle case where playerId was provided but document doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player not found for editing.')));
        Navigator.pop(context); // Go back if player doesn't exist
      }
    } catch (e) {
      print("Error loading player data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load player data.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Function to save or update player data
  Future<void> _savePlayer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Prepare data map
      Map<String, dynamic> playerData = {
        'playerName': _playerNameController.text.trim(),
        'position': _positionController.text.trim(),
        'teamId': widget.teamId, // Link to the team
        'teamName': widget.teamName, // Store team name for easier display
        'timestamp': FieldValue.serverTimestamp(), // Update timestamp on save
        // Add stats fields (parse to int, default to 0)
        'goals': int.tryParse(_goalsController.text.trim()) ?? 0,
        'assists': int.tryParse(_assistsController.text.trim()) ?? 0,
        'gamesPlayed': int.tryParse(_gamesPlayedController.text.trim()) ?? 0,
        // Process achievements from the text field (split by comma and trim)
        'achievements': _achievementsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(), // Save as List<String>
      };


      try {
        if (widget.playerId == null) {
          // Add new player
          await FirebaseFirestore.instance.collection('players').add(playerData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player added successfully!')));
        } else {
          // Update existing player
          await FirebaseFirestore.instance.collection('players').doc(widget.playerId).update(playerData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player updated successfully!')));
        }
        // Clear form fields only if adding
        if (!_isEditing) {
          _playerNameController.clear();
          _positionController.clear();
          _goalsController.clear();
          _assistsController.clear();
          _gamesPlayedController.clear();
          _achievementsController.clear();
        } else {
          // If editing, pop the screen after successful update
          Navigator.pop(context);
        }

      } catch (e) {
        print("Error saving player: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save player.')));
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
        title: Text(_isEditing ? 'Edit Player' : 'Register Player (${widget.teamName})'),
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
                controller: _playerNameController,
                decoration: InputDecoration(labelText: 'Player Name'),
                validator: (val) => val!.isEmpty ? 'Enter player name' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(labelText: 'Position'),
                validator: (val) => val!.isEmpty ? 'Enter position' : null,
              ),
              SizedBox(height: 24.0), // Add space before stats section

              // --- Stats Section ---
              Text(
                'Stats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _goalsController,
                decoration: InputDecoration(labelText: 'Goals'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null; // Optional field, no validation if empty
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _assistsController,
                decoration: InputDecoration(labelText: 'Assists'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null; // Optional field
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _gamesPlayedController,
                decoration: InputDecoration(labelText: 'Games Played'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null; // Optional field
                },
              ),
              SizedBox(height: 24.0), // Add space before achievements

              // --- Achievements Section ---
              Text(
                'Achievements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _achievementsController,
                decoration: InputDecoration(
                  labelText: 'Achievements (comma-separated)',
                  hintText: 'e.g., MVP 2023, All-Star Team',
                ),
                maxLines: null, // Allow multiple lines
                keyboardType: TextInputType.multiline,
              ),
              SizedBox(height: 24.0),


              ElevatedButton(
                child: Text(_isEditing ? 'Update Player' : 'Register Player'),
                onPressed: _savePlayer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
