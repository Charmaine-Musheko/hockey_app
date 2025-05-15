import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerRegistrationScreen extends StatefulWidget {
  // Optional: Pass a player document ID if editing an existing player
  final String? playerId;

  // Remove teamId and teamName parameters as the screen will fetch teams
  // final String teamId;
  // final String teamName;

  const PlayerRegistrationScreen({Key? key, this.playerId}) : super(key: key);
  // Removed required teamId and teamName from constructor
  // const PlayerRegistrationScreen({Key? key, required this.teamId, required this.teamName, this.playerId}) : super(key: key);


  @override
  _PlayerRegistrationScreenState createState() => _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState extends State<PlayerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _jerseyNumberController = TextEditingController();

  String? _selectedTeamId; // To store the selected team's document ID
  List<DropdownMenuItem<String>> _teamDropdownItems = []; // List to hold team dropdown items
  Map<String, String> _teamNames = {}; // Map to store team IDs and names

  bool _isLoading = false; // To show a loading indicator
  bool _isFetchingTeams = true; // To indicate if teams are being fetched
  bool _isEditing = false; // To know if we are editing or adding

  @override
  void initState() {
    super.initState();
    _fetchTeams(); // Fetch teams when the screen initializes

    if (widget.playerId != null) {
      _isEditing = true; // Set editing mode
      _loadPlayerData(widget.playerId!); // Load player data if editing
    }
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _positionController.dispose();
    _jerseyNumberController.dispose();
    super.dispose();
  }

  // Function to fetch the list of teams from Firestore
  Future<void> _fetchTeams() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('teams').orderBy('teamName').get();
      List<DropdownMenuItem<String>> items = [];
      Map<String, String> names = {};

      for (var doc in snapshot.docs) {
        final teamData = doc.data() as Map<String, dynamic>;
        final teamId = doc.id;
        final teamName = teamData['teamName'] ?? 'Unnamed Team';
        items.add(DropdownMenuItem(
          value: teamId,
          child: Text(teamName),
        ));
        names[teamId] = teamName;
      }

      setState(() {
        _teamDropdownItems = items;
        _teamNames = names;
        _isFetchingTeams = false; // Finished fetching teams
        // If editing and team data is loaded, set the selected team
        if (_isEditing && _selectedTeamId != null && _teamNames.containsKey(_selectedTeamId)) {
          // The loadPlayerData function will set _selectedTeamId
          // We just need to make sure the dropdown updates after teams are fetched
          // No explicit action needed here if loadPlayerData runs after _fetchTeams
        } else if (!_isEditing && _teamDropdownItems.isNotEmpty) {
          // For adding, automatically select the first team if available
          _selectedTeamId = _teamDropdownItems.first.value;
        }
      });

    } catch (e) {
      print("Error fetching teams: $e");
      setState(() {
        _isFetchingTeams = false;
        // Optionally show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load teams.')));
      });
    }
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
        _jerseyNumberController.text = data['jerseyNumber']?.toString() ?? '';
        _selectedTeamId = data['teamId']; // Load the player's team ID

        // Ensure the dropdown is updated after teams are fetched
        if (!_isFetchingTeams && _teamNames.containsKey(_selectedTeamId)) {
          // If teams are already fetched, set the selected team immediately
          setState(() {}); // Trigger rebuild to update dropdown
        }

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
      // Ensure a team is selected
      if (_selectedTeamId == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a team.')));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Prepare data map
      Map<String, dynamic> playerData = {
        'playerName': _playerNameController.text.trim(),
        'position': _positionController.text.trim(),
        'jerseyNumber': int.tryParse(_jerseyNumberController.text.trim()) ?? null, // Save as int, null if parsing fails
        'teamId': _selectedTeamId, // Save the selected team ID
        'teamName': _teamNames[_selectedTeamId], // Optionally save team name for easier display later
        'timestamp': FieldValue.serverTimestamp(), // For ordering in lists
      };

      try {
        if (widget.playerId == null) {
          // Add new player
          await FirebaseFirestore.instance.collection('players').add(playerData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player registered successfully!')));
        } else {
          // Update existing player
          await FirebaseFirestore.instance.collection('players').doc(widget.playerId).update(playerData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player updated successfully!')));
        }
        // Clear form fields only if adding
        if (!_isEditing) {
          _playerNameController.clear();
          _positionController.clear();
          _jerseyNumberController.clear();
          // Keep selected team or reset based on preference
          // setState(() { _selectedTeamId = null; }); // Uncomment to reset selected team
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
        title: Text(widget.playerId == null ? 'Register New Player' : 'Edit Player'),
      ),
      body: _isLoading || _isFetchingTeams // Show loading if saving or fetching teams
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrolling if content overflows
            children: [
              // Team Selection Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select Team'),
                value: _selectedTeamId, // Current selected value
                items: _teamDropdownItems, // List of dropdown items
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTeamId = newValue;
                  });
                },
                validator: (val) => val == null ? 'Please select a team' : null,
                // Disable dropdown if no teams are available
                // enabled: _teamDropdownItems.isNotEmpty, // This might be too restrictive if fetching failed
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _playerNameController,
                decoration: InputDecoration(labelText: 'Player Name'),
                validator: (val) => val!.isEmpty ? 'Enter player name' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(labelText: 'Position (e.g., Forward, Defense, Goalie)'),
                validator: (val) => val!.isEmpty ? 'Enter player position' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _jerseyNumberController,
                decoration: InputDecoration(labelText: 'Jersey Number (Optional)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number'; // Ensure it's a number if entered
                  }
                  return null; // No error or optional field
                },
              ),
              // TODO: Add fields for player stats, achievements etc. later
              SizedBox(height: 24.0),
              ElevatedButton(
                child: Text(widget.playerId == null ? 'Register Player' : 'Update Player'),
                onPressed: _savePlayer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
