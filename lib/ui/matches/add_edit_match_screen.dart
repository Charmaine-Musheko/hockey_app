import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AddEditMatchScreen extends StatefulWidget {
  // Optional: Pass a match document ID if editing an existing match
  final String? matchId;

  const AddEditMatchScreen({Key? key, this.matchId}) : super(key: key);

  @override
  // Corrected the return type from _AddEditMatchScreenState to _AddEditMatchState
  _AddEditMatchState createState() => _AddEditMatchState();
}

class _AddEditMatchState extends State<AddEditMatchScreen> {
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
  bool _isEditing = false; // To know if we are editing or adding

  // Fetch existing match data if matchId is provided (for editing)
  @override
  void initState() {
    super.initState();
    if (widget.matchId != null) {
      _isEditing = true; // Set editing mode
      _loadMatchData(widget.matchId!);
    } else {
      // For adding a new match, set default time to something reasonable if needed
      _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1))); // Default to 1 hour from now
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
        // Load scores, defaulting to empty string if null or not present
        _homeScoreController.text = (data['homeTeamScore']?.toString() ?? '0');
        _awayScoreController.text = (data['awayTeamScore']?.toString() ?? '0');

        _selectedStatus = data['status'] ?? 'Scheduled';

        final Timestamp matchTimestamp = data['matchDate'] ?? Timestamp.now();
        final DateTime matchDateTime = matchTimestamp.toDate();
        _selectedDate = DateTime(matchDateTime.year, matchDateTime.month, matchDateTime.day);
        _selectedTime = TimeOfDay(hour: matchDateTime.hour, minute: matchDateTime.minute);
      } else {
        // Handle case where matchId was provided but document doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Match not found for editing.')));
        Navigator.pop(context); // Go back if match doesn't exist
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
    // Only validate team names and location if adding a new match
    // or if the status is Scheduled (meaning core details are being set)
    bool isValid = true;
    if (!_isEditing || _selectedStatus == 'Scheduled') {
      if (_formKey.currentState!.validate()) {
        isValid = true;
      } else {
        isValid = false;
      }
    } else {
      // If editing and status is not Scheduled, validation might be less strict
      // (e.g., just need scores/status to be valid)
      // For simplicity, we'll assume validation passes if not adding/scheduling
      isValid = true; // Adjust this logic if specific score validation is needed
    }


    if (isValid) {
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
        // Only include team names and location if adding or status is Scheduled
        if (!_isEditing || _selectedStatus == 'Scheduled') ...{
          'homeTeamName': _homeTeamController.text.trim(),
          'awayTeamName': _awayTeamController.text.trim(),
          'location': _locationController.text.trim(),
          'matchDate': Timestamp.fromDate(matchDateTime),
          'timestamp': FieldValue.serverTimestamp(), // Update timestamp on save
        },
        'status': _selectedStatus,
      };

      // Add scores only if status is completed or in progress
      if (_selectedStatus == 'Completed' || _selectedStatus == 'InProgress') {
        matchData['homeTeamScore'] = int.tryParse(_homeScoreController.text.trim()) ?? 0;
        matchData['awayTeamScore'] = int.tryParse(_awayScoreController.text.trim()) ?? 0;
      } else {
        // Ensure score fields are not saved if status is not score-related
        // Or set them to 0 if you prefer to keep the fields
        matchData['homeTeamScore'] = 0; // Set to 0 when not InProgress/Completed
        matchData['awayTeamScore'] = 0; // Set to 0 when not InProgress/Completed
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
        // Clear form fields only if adding
        if (!_isEditing) {
          _homeTeamController.clear();
          _awayTeamController.clear();
          _locationController.clear();
          _homeScoreController.clear();
          _awayScoreController.clear();
          setState(() {
            _selectedDate = DateTime.now();
            _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));
            _selectedStatus = 'Scheduled';
          });
        } else {
          // If editing, pop the screen after successful update
          Navigator.pop(context);
        }

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
    // Determine if team name/location fields should be enabled
    // They are typically only editable when the match is Scheduled or being added
    final bool areDetailsEditable = !_isEditing || _selectedStatus == 'Scheduled';

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
              // Team Name Fields (Editable only when adding or status is Scheduled)
              TextFormField(
                controller: _homeTeamController,
                decoration: InputDecoration(labelText: 'Home Team Name'),
                validator: areDetailsEditable ? (val) => val!.isEmpty ? 'Enter home team name' : null : null, // Validate only if editable
                enabled: areDetailsEditable, // Disable if not editable
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _awayTeamController,
                decoration: InputDecoration(labelText: 'Away Team Name'),
                validator: areDetailsEditable ? (val) => val!.isEmpty ? 'Enter away team name' : null : null, // Validate only if editable
                enabled: areDetailsEditable, // Disable if not editable
              ),
              SizedBox(height: 16.0),

              // Date Picker (Editable only when adding or status is Scheduled)
              ListTile(
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: areDetailsEditable ? () => _selectDate(context) : null, // Disable tap if not editable
                enabled: areDetailsEditable, // Disable if not editable
              ),
              SizedBox(height: 8.0),
              // Time Picker (Editable only when adding or status is Scheduled)
              ListTile(
                title: Text('Time: ${_selectedTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: areDetailsEditable ? () => _selectTime(context) : null, // Disable tap if not editable
                enabled: areDetailsEditable, // Disable if not editable
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: areDetailsEditable ? (val) => val!.isEmpty ? 'Enter location' : null : null, // Validate only if editable
                enabled: areDetailsEditable, // Disable if not editable
              ),
              SizedBox(height: 16.0),

              // Status Dropdown (Always editable when editing)
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
                      // Clear scores if status changes to something not score-related
                      if (newValue != 'Completed' && newValue != 'InProgress') {
                        _homeScoreController.text = '0';
                        _awayScoreController.text = '0';
                      }
                    });
                  }
                },
                // Disable status editing if adding a new match? Or allow setting initial status?
                // For now, let's allow changing status when adding too.
              ),
              SizedBox(height: 16.0),

              // Score Fields (Always editable when editing, or if status allows)
              // We'll make them always visible when editing a match,
              // but only required/relevant when status is InProgress or Completed.
              TextFormField(
                controller: _homeScoreController,
                decoration: InputDecoration(labelText: 'Home Team Score'),
                keyboardType: TextInputType.number,
                // Validation: Optional, but could ensure it's a number
                validator: (val) {
                  if ((_selectedStatus == 'Completed' || _selectedStatus == 'InProgress') && (val == null || val.isEmpty)) {
                    return 'Enter score'; // Require score if status is score-related
                  }
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number'; // Ensure it's a number if entered
                  }
                  return null; // No error
                },
                // Enabled only when editing? Or always enabled if status allows?
                // Let's keep it always enabled when editing for ease of update
                enabled: _isEditing || _selectedStatus == 'Completed' || _selectedStatus == 'InProgress',
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _awayScoreController,
                decoration: InputDecoration(labelText: 'Away Team Score'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if ((_selectedStatus == 'Completed' || _selectedStatus == 'InProgress') && (val == null || val.isEmpty)) {
                    return 'Enter score'; // Require score if status is score-related
                  }
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid number'; // Ensure it's a number if entered
                  }
                  return null; // No error
                },
                enabled: _isEditing || _selectedStatus == 'Completed' || _selectedStatus == 'InProgress',
              ),
              SizedBox(height: 16.0),

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
