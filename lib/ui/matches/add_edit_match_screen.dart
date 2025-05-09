import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AddEditMatchScreen extends StatefulWidget {
  // Optional: Pass a match document ID if editing an existing match
  final String? matchId;

  const AddEditMatchScreen({Key? key, this.matchId}) : super(key: key);

  @override
  _AddEditMatchScreenState createState() => _AddEditMatchScreenState();
}

class _AddEditMatchScreenState extends State<AddEditMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _homeTeamController = TextEditingController();
  final TextEditingController _awayTeamController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _homeScoreController = TextEditingController();
  final TextEditingController _awayScoreController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedStatus = 'Scheduled'; // Default status
  List<String> _statuses = ['Scheduled', 'InProgress', 'Completed', 'Postponed', 'Cancelled'];

  bool _isLoading = false; // To show a loading indicator

  // Fetch existing match data if matchId is provided (for editing)
  @override
  void initState() {
    super.initState();
    if (widget.matchId != null) {
      _loadMatchData(widget.matchId!);
    }
  }

  // Dispose controllers when the widget is removed
  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _locationController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
  }

  // Function to load data for editing
  Future<void> _loadMatchData(String matchId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _homeTeamController.text = data['homeTeamName'] ?? '';
        _awayTeamController.text = data['awayTeamName'] ?? '';
        _locationController.text = data['location'] ?? '';
        _homeScoreController.text = data['homeTeamScore']?.toString() ?? '';
        _awayScoreController.text = data['awayTeamScore']?.toString() ?? '';
        _selectedStatus = data['status'] ?? 'Scheduled';

        final Timestamp matchTimestamp = data['matchDate'] ?? Timestamp.now();
        final DateTime matchDateTime = matchTimestamp.toDate();
        _selectedDate = DateTime(matchDateTime.year, matchDateTime.month, matchDateTime.day);
        _selectedTime = TimeOfDay(hour: matchDateTime.hour, minute: matchDateTime.minute);
      }
    } catch (e) {
      print("Error loading match data: $e");
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load match data.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023), // Adjust as needed
      lastDate: DateTime(2030), // Adjust as needed
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to show time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Function to save or update match data
  Future<void> _saveMatch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Combine selected date and time
      final DateTime matchDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Prepare data map
      Map<String, dynamic> matchData = {
        'homeTeamName': _homeTeamController.text.trim(),
        'awayTeamName': _awayTeamController.text.trim(),
        // TODO: Ideally, use team IDs here and fetch names for display
        // 'homeTeamId': '...',
        // 'awayTeamId': '...',
        'matchDate': Timestamp.fromDate(matchDateTime),
        'location': _locationController.text.trim(),
        'status': _selectedStatus,
        'timestamp': FieldValue.serverTimestamp(), // For ordering in lists
      };

      // Add scores only if status is completed or in progress
      if (_selectedStatus == 'Completed' || _selectedStatus == 'InProgress') {
        matchData['homeTeamScore'] = int.tryParse(_homeScoreController.text.trim()) ?? 0;
        matchData['awayTeamScore'] = int.tryParse(_awayScoreController.text.trim()) ?? 0;
      } else {
        // Ensure score fields are not saved if status is not score-related
        matchData['homeTeamScore'] = null;
        matchData['awayTeamScore'] = null;
      }


      try {
        if (widget.matchId == null) {
          // Add new match
          await FirebaseFirestore.instance.collection('matches').add(matchData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Match added successfully!')));
        } else {
          // Update existing match
          await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update(matchData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Match updated successfully!')));
        }
        Navigator.pop(context); // Go back after saving
      } catch (e) {
        print("Error saving match: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save match.')));
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
        title: Text(widget.matchId == null ? 'Add New Match' : 'Edit Match'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrolling if content overflows
            children: [
              TextFormField(
                controller: _homeTeamController,
                decoration: InputDecoration(labelText: 'Home Team Name'),
                validator: (val) => val!.isEmpty ? 'Enter home team name' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _awayTeamController,
                decoration: InputDecoration(labelText: 'Away Team Name'),
                validator: (val) => val!.isEmpty ? 'Enter away team name' : null,
              ),
              SizedBox(height: 16.0),
              // Date Picker
              ListTile(
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 8.0),
              // Time Picker
              ListTile(
                title: Text('Time: ${_selectedTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (val) => val!.isEmpty ? 'Enter location' : null,
              ),
              SizedBox(height: 16.0),
              // Status Dropdown
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(labelText: 'Status'),
                items: _statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
                },
              ),
              SizedBox(height: 16.0),

              // Show score fields only if status is Completed or InProgress
              if (_selectedStatus == 'Completed' || _selectedStatus == 'InProgress') ...[
                TextFormField(
                  controller: _homeScoreController,
                  decoration: InputDecoration(labelText: 'Home Team Score'),
                  keyboardType: TextInputType.number,
                  // Validator is optional here, can allow empty if score not finalized
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _awayScoreController,
                  decoration: InputDecoration(labelText: 'Away Team Score'),
                  keyboardType: TextInputType.number,
                  // Validator is optional here
                ),
                SizedBox(height: 16.0),
              ],

              ElevatedButton(
                child: Text(widget.matchId == null ? 'Add Match' : 'Update Match'),
                onPressed: _saveMatch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
