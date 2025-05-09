import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AddEditEventScreen extends StatefulWidget {
  // Optional: Pass an event document ID if editing an existing event
  final String? eventId;

  const AddEditEventScreen({Key? key, this.eventId}) : super(key: key);

  @override
  _AddEditEventScreenState createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  final TextEditingController _totalTicketsController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  DateTime _selectedStartDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  DateTime? _selectedEndDate; // Optional end date
  TimeOfDay? _selectedEndTime; // Optional end time
  String _selectedType = 'Tournament'; // Default type
  List<String> _eventTypes = ['Tournament', 'Match', 'Clinic', 'Meeting', 'Other'];

  bool _isLoading = false; // To show a loading indicator
  bool _isEditing = false; // To know if we are editing or adding

  // Fetch existing event data if eventId is provided (for editing)
  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _isEditing = true; // Set editing mode
      _loadEventData(widget.eventId!);
    } else {
      // Set default start time for new events
      _selectedStartTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));
    }
  }

  // Dispose controllers when the widget is removed
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _ticketPriceController.dispose();
    _totalTicketsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // Function to load data for editing
  Future<void> _loadEventData(String eventId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _locationController.text = data['location'] ?? '';
        _ticketPriceController.text = (data['ticketPrice']?.toString() ?? '');
        _totalTicketsController.text = (data['totalTickets']?.toString() ?? '');
        _imageUrlController.text = data['imageUrl'] ?? '';
        _selectedType = data['type'] ?? 'Tournament';

        final Timestamp startTimestamp = data['startDate'] ?? Timestamp.now();
        final DateTime startDateTime = startTimestamp.toDate();
        _selectedStartDate = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
        _selectedStartTime = TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute);

        if (data['endDate'] != null) {
          final Timestamp endTimestamp = data['endDate'];
          final DateTime endDateTime = endTimestamp.toDate();
          _selectedEndDate = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
          _selectedEndTime = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);
        }

      } else {
        // Handle case where eventId was provided but document doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event not found for editing.')));
        Navigator.pop(context); // Go back if event doesn't exist
      }
    } catch (e) {
      print("Error loading event data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load event data.')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : (_selectedEndDate ?? _selectedStartDate),
      firstDate: DateTime(2023), // Adjust as needed
      lastDate: DateTime(2030), // Adjust as needed
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          // Ensure end date is not before start date
          if (_selectedEndDate != null && _selectedEndDate!.isBefore(_selectedStartDate)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = picked;
          // Ensure end date is not before start date
          if (_selectedEndDate != null && _selectedEndDate!.isBefore(_selectedStartDate)) {
            _selectedEndDate = _selectedStartDate;
          }
        }
      });
    }
  }

  // Function to show time picker
  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _selectedStartTime : (_selectedEndTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }


  // Function to save or update event data
  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Combine selected start date and time
      final DateTime startDateTime = DateTime(
        _selectedStartDate.year,
        _selectedStartDate.month,
        _selectedStartDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );

      // Combine selected end date and time if end date is selected
      DateTime? endDateTime;
      if (_selectedEndDate != null && _selectedEndTime != null) {
        endDateTime = DateTime(
          _selectedEndDate!.year,
          _selectedEndDate!.month,
          _selectedEndDate!.day,
          _selectedEndTime!.hour,
          _selectedEndTime!.minute,
        );
        // Ensure end date/time is not before start date/time
        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = startDateTime; // Default end to start if invalid
        }
      }


      // Prepare data map
      Map<String, dynamic> eventData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'startDate': Timestamp.fromDate(startDateTime),
        'endDate': endDateTime != null ? Timestamp.fromDate(endDateTime) : null, // Save end date if available
        'type': _selectedType,
        'ticketPrice': double.tryParse(_ticketPriceController.text.trim()) ?? 0.0, // Default to 0.0 if parsing fails
        'totalTickets': int.tryParse(_totalTicketsController.text.trim()) ?? 0, // Default to 0 if parsing fails
        // Available tickets will be managed separately, or initialized here
        'availableTickets': int.tryParse(_totalTicketsController.text.trim()) ?? 0, // Initialize available to total
        'imageUrl': _imageUrlController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(), // Update timestamp on save
      };


      try {
        if (widget.eventId == null) {
          // Add new event
          await FirebaseFirestore.instance.collection('events').add(eventData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event added successfully!')));
        } else {
          // Update existing event
          await FirebaseFirestore.instance.collection('events').doc(widget.eventId).update(eventData);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event updated successfully!')));
        }
        // Clear form fields only if adding
        if (!_isEditing) {
          _nameController.clear();
          _descriptionController.clear();
          _locationController.clear();
          _ticketPriceController.clear();
          _totalTicketsController.clear();
          _imageUrlController.clear();
          setState(() {
            _selectedStartDate = DateTime.now();
            _selectedStartTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));
            _selectedEndDate = null;
            _selectedEndTime = null;
            _selectedType = 'Tournament';
          });
        } else {
          // If editing, pop the screen after successful update
          Navigator.pop(context);
        }

      } catch (e) {
        print("Error saving event: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save event.')));
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
        title: Text(widget.eventId == null ? 'Add New Event' : 'Edit Event'),
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
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Event Name'),
                validator: (val) => val!.isEmpty ? 'Enter event name' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (val) => val!.isEmpty ? 'Enter event description' : null,
                maxLines: 5, // Allow multiple lines
                keyboardType: TextInputType.multiline,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (val) => val!.isEmpty ? 'Enter location' : null,
              ),
              SizedBox(height: 16.0),

              // Start Date Picker
              ListTile(
                title: Text('Start Date: ${DateFormat('yyyy-MM-dd').format(_selectedStartDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: true),
              ),
              SizedBox(height: 8.0),
              // Start Time Picker
              ListTile(
                title: Text('Start Time: ${_selectedStartTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectTime(context, isStartTime: true),
              ),
              SizedBox(height: 16.0),

              // Optional End Date Picker
              ListTile(
                title: Text('End Date: ${_selectedEndDate == null ? 'Optional' : DateFormat('yyyy-MM-dd').format(_selectedEndDate!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, isStartDate: false),
              ),
              SizedBox(height: 8.0),
              // Optional End Time Picker
              ListTile(
                title: Text('End Time: ${_selectedEndTime == null ? 'Optional' : _selectedEndTime!.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectTime(context, isStartTime: false),
              ),
              SizedBox(height: 16.0),

              // Event Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'Event Type'),
                items: _eventTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),
              SizedBox(height: 16.0),

              // Ticket Information Fields
              TextFormField(
                controller: _ticketPriceController,
                decoration: InputDecoration(labelText: 'Ticket Price (e.g., 50.00, 0 for Free)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _totalTicketsController,
                decoration: InputDecoration(labelText: 'Total Tickets Available (0 for unlimited/N/A)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Enter a valid integer';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL (Optional)'),
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 24.0),


              ElevatedButton(
                child: Text(widget.eventId == null ? 'Add Event' : 'Update Event'),
                onPressed: _saveEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
