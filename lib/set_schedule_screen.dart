// lib/set_schedule_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:intl/intl.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/l10n/app_localizations.dart';
import 'package:medguard/login_screen.dart';
import 'package:medguard/models/api_response.dart';

class SetScheduleScreen extends StatefulWidget {
  final int userMedicineId;
  final Map<String, dynamic>? existingSchedule;

  const SetScheduleScreen({
    super.key,
    required this.userMedicineId,
    this.existingSchedule
  });

  @override
  State<SetScheduleScreen> createState() => _SetScheduleScreenState();
}

class _SetScheduleScreenState extends State<SetScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dosageController = TextEditingController();
  final _instructionController = TextEditingController();
  final List<TimeOfDay> _selectedTimes = [];
  final ApiService _apiService = ApiService.instance;

  // State for the new features
  bool _isLoadingDetails = true;
  bool _isSaving = false;
  bool _agreedToInstructions = false;
  Map<String, dynamic>? _medicineDetails;

  @override
  void initState() {
    super.initState();
    _fetchDetailsAndInitializeForm();
  }

  Future<void> _fetchDetailsAndInitializeForm() async {
    final details = await _apiService.getMedicineDetails(widget.userMedicineId);
    if (details != null && mounted) {
      setState(() {
        _medicineDetails = details;
        
        if (widget.existingSchedule != null) {
          _dosageController.text = widget.existingSchedule!['Dosage'] ?? '';
          _instructionController.text = widget.existingSchedule!['Instruction'] ?? '';

          final timesString = widget.existingSchedule!['TimesToTake'];
          if (timesString != null && timesString.isNotEmpty) {
            try {
              final List<dynamic> timesJson = json.decode(timesString);
              for (var timeStr in timesJson) {
                final parts = timeStr.split(':');
                if (parts.length == 2) {
                  _selectedTimes.add(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
                }
              }
            } catch (e) {
              logger.e("Error parsing TimesToTake: $e");
            }
          }
        } else {
          _dosageController.text = '1 tablet';
          _instructionController.text = 'After food';
        }
        _isLoadingDetails = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load medicine details.')));
    }
  }

  void _addTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newTime != null) {
      setState(() {
        _selectedTimes.add(newTime);
        _selectedTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  void _removeTime(TimeOfDay timeToRemove) {
    setState(() {
      _selectedTimes.remove(timeToRemove);
    });
  }

  void _saveSchedule() async {
    if (!_formKey.currentState!.validate() || _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and add at least one time.')),
      );
      return;
    }
    
    setState(() => _isSaving = true);

    final timesAsString = _selectedTimes.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').toList();
    final scheduleData = {
      "userMedicineID": widget.userMedicineId,
      "dosage": _dosageController.text,
      "frequency": "Daily",
      "timesToTake": json.encode(timesAsString),
      "instruction": _instructionController.text,
      "startDate": DateTime.now().toIso8601String(),
      "endDate": null,
    };

    final ApiResponse response = await _apiService.setSchedule(scheduleData);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'An unknown error occurred.'),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );
      if (response.success) {
        logger.e("---[SetScheduleScreen]: Popping with TRUE ---"); 
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_medicineDetails?['MedicineName'] ?? 'Set Schedule')),
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_medicineDetails != null) ...[
                    Text(_medicineDetails!['MedicineName'] ?? '', style: Theme.of(context).textTheme.headlineMedium),
                    const Divider(height: 30, thickness: 1),
                    _buildInstructionSection('Instructions', _medicineDetails!['Instructions']),
                    _buildInstructionSection('Warnings', _medicineDetails!['Warnings']),
                    _buildInstructionSection('Side Effects', _medicineDetails!['SideEffects']),
                    const Divider(height: 30, thickness: 1),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _dosageController,
                          decoration: const InputDecoration(labelText: 'Dosage (e.g., 1 tablet)'),
                          validator: (value) => value!.isEmpty ? 'Please enter dosage' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _instructionController,
                          decoration: const InputDecoration(labelText: 'Instruction (e.g., After food)'),
                        ),
                        const SizedBox(height: 30),
                        Text('Reminder Times', style: Theme.of(context).textTheme.titleMedium),
                        Wrap(
                          spacing: 8.0,
                          children: _selectedTimes.map((time) => Chip(
                            label: Text(time.format(context)),
                            onDeleted: () => _removeTime(time),
                          )).toList(),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add_alarm),
                          label: const Text('Add Time'),
                          onPressed: _addTime,
                        ),
                      ],
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text("I have read and agree to the instructions."),
                    value: _agreedToInstructions,
                    onChanged: (newValue) {
                      setState(() => _agreedToInstructions = newValue ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_agreedToInstructions && !_isSaving) ? _saveSchedule : null,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.saveChanges),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
/*// lib/set_schedule_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import 'package:medicine_reminder_app/api_service.dart';
import 'package:medicine_reminder_app/models/api_response.dart';
import 'package:medicine_reminder_app/scan_screen.dart';

class SetScheduleScreen extends StatefulWidget {
  final int userMedicineId;
  // NEW: Add an optional parameter to accept an existing schedule
  final Map<String, dynamic>? existingSchedule;

  const SetScheduleScreen({
    super.key, 
    required this.userMedicineId, 
    this.existingSchedule
  });

  @override
  State<SetScheduleScreen> createState() => _SetScheduleScreenState();
}

class _SetScheduleScreenState extends State<SetScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dosageController = TextEditingController();
  final _instructionController = TextEditingController();
  final List<TimeOfDay> _selectedTimes = [];
  bool _isLoading = false;
 final ApiService _apiService = ApiService.instance;

  @override
  void initState() {
    super.initState();
    // NEW: Check if we are in "edit mode"
    if (widget.existingSchedule != null) {
      // Pre-fill the form fields with the existing data
      //_dosageController.text = widget.existingSchedule!['Dosage'];
      //_instructionController.text = widget.existingSchedule!['Instruction'];
      // --- THIS IS THE FIX ---
      // We add '?? ??' to provide a default empty string if the database value is NULL.
      _dosageController.text = widget.existingSchedule!['Dosage'] ?? '';
      _instructionController.text = widget.existingSchedule!['Instruction'] ?? '';
      // --- END OF FIX ---
      // Parse the TimesToTake JSON string and populate the times list
      final timesString = widget.existingSchedule!['TimesToTake'];
      if (timesString != null && timesString.isNotEmpty) {
        try{
        final List<dynamic> timesJson = json.decode(timesString);
        for (var timeStr in timesJson) {
          final parts = timeStr.split(':');
          if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          // ignore: unnecessary_null_comparison
          if (hour != null && minute != null) {
          _selectedTimes.add(TimeOfDay(hour: hour, minute: minute));
        }
      }
    } 
    }
    catch(e) {
          logger.e("Error parsing TimesToTake: $e");
    }
  }
  }
        else {
      // If creating a new schedule, use default values
      _dosageController.text = '1 tablet';
      _instructionController.text = 'After food';
    }
  }

  void _addTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newTime != null) {
      setState(() {
        _selectedTimes.add(newTime);
        _selectedTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      });
    }
  }

  void _removeTime(TimeOfDay timeToRemove) {
    setState(() {
      _selectedTimes.remove(timeToRemove);
    });
  }
  
  // In lib/set_schedule_screen.dart

void _saveSchedule() async {
  if (_formKey.currentState!.validate() && _selectedTimes.isNotEmpty) {
    setState(() => _isLoading = true);

    final timesAsString = _selectedTimes.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').toList();

    final scheduleData = {
      "userMedicineID": widget.userMedicineId,
      "dosage": _dosageController.text,
      "frequency": "Daily",
      "timesToTake": json.encode(timesAsString),
      "instruction": _instructionController.text,
      "startDate": DateTime.now().toIso8601String(),
      "endDate": null,
    };

    // The method now returns our ApiResponse object
    final ApiResponse response = await _apiService.setSchedule(scheduleData);

    setState(() => _isLoading = false);

    if (mounted) {
      // Show the message from the API response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'An unknown error occurred.'),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );

      // If successful, go back
      if (response.success) {
        Navigator.pop(context, true);
      }
    }
  } else if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time.')),
      );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingSchedule != null ? 'Edit Schedule' : 'Set Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (e.g., 1 tablet)'),
                validator: (value) => value!.isEmpty ? 'Please enter dosage' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _instructionController,
                decoration: const InputDecoration(labelText: 'Instruction (e.g., After food)'),
              ),
              const SizedBox(height: 30),
              Text('Reminder Times', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8.0,
                children: _selectedTimes.map((time) => Chip(
                  label: Text(time.format(context)),
                  onDeleted: () => _removeTime(time),
                )).toList(),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_alarm),
                label: const Text('Add Time'),
                onPressed: _addTime,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Schedule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
/*// lib/set_schedule_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:intl/intl.dart';
import 'package:medicine_reminder_app/api_service.dart';

class SetScheduleScreen extends StatefulWidget {
  final int userMedicineId;

  const SetScheduleScreen({super.key, required this.userMedicineId});

  @override
  State<SetScheduleScreen> createState() => _SetScheduleScreenState();
}

class _SetScheduleScreenState extends State<SetScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dosageController = TextEditingController(text: '1 tablet');
  final _instructionController = TextEditingController(text: 'After food');
  final List<TimeOfDay> _selectedTimes = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  void _addTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newTime != null) {
      setState(() {
        _selectedTimes.add(newTime);
      });
    }
  }
  
  void _saveSchedule() async {
    if (_formKey.currentState!.validate() && _selectedTimes.isNotEmpty) {
      setState(() => _isLoading = true);
      
      // Convert times to "HH:mm" format for the API
      final timesAsString = _selectedTimes.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').toList();

      final scheduleData = {
        "userMedicineID": widget.userMedicineId,
        "dosage": _dosageController.text,
        "frequency": "Daily", // For now, we'll keep this simple
        "timesToTake": json.encode(timesAsString),
        "instruction": _instructionController.text,
        "startDate": DateTime.now().toIso8601String(),
        "endDate": null,
      };

      bool success = await _apiService.setSchedule(scheduleData);

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context, true); // Pop back and signal success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save schedule.')),
        );
      }
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one time.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Reminder Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (e.g., 1 tablet)'),
                validator: (value) => value!.isEmpty ? 'Please enter dosage' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _instructionController,
                decoration: const InputDecoration(labelText: 'Instruction (e.g., After food)'),
              ),
              const SizedBox(height: 30),
              const Text('Reminder Times', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: _selectedTimes.map((time) => Chip(label: Text(time.format(context)))).toList(),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_alarm),
                label: const Text('Add Time'),
                onPressed: _addTime,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Schedule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/