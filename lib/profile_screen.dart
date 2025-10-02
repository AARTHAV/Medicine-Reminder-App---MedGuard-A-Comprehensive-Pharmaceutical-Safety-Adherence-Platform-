// lib/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/l10n/app_localizations.dart';
import 'package:medguard/login_screen.dart';
import 'package:medguard/models/api_response.dart';
import 'package:medguard/providers/settings_provider.dart';
//import 'package:medicine_reminder_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _allergiesController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = true;
  String _mobileNumber = '';
  String? _imageUrl;

  final ApiService _apiService = ApiService.instance;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profileData = await _apiService.getProfile();
    if (profileData != null) {
      _nameController.text = profileData['Name'] ?? '';
      _allergiesController.text = profileData['Allergies'] ?? '';
      _mobileNumber = profileData['MobileNumber'] ?? '';
      _imageUrl = profileData['ProfileImageUrl'];
      if (profileData['DateOfBirth'] != null) {
        _selectedDate = DateTime.parse(profileData['DateOfBirth']);
      }
    }
    setState(() => _isLoading = false);
  }
// NEW: Method to handle picking and uploading the image
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return; // User cancelled the picker

    final newImageUrl = await _apiService.uploadProfileImage(image.path);
    if (newImageUrl != null) {
      setState(() {
        _imageUrl = newImageUrl;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated!'), backgroundColor: Colors.green),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image.'), backgroundColor: Colors.red),
      );
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now());
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);
      final profileData = {
        'Name': _nameController.text,
        'DateOfBirth': _selectedDate!.toIso8601String(),
        'Allergies': _allergiesController.text,
      };
      final ApiResponse response = await _apiService.updateProfile(profileData);
        if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response.message ?? 'An unknown error occurred.'),
        backgroundColor: response.success ? Colors.green : Colors.red,
      ));
    }
  }
}
      /*bool success = await _apiService.updateProfile(profileData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Profile updated successfully!' : 'Failed to update profile.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
        setState(() => _isLoading = false);
      }
    }
  }*/
Future<void> _logout() async {
  await _apiService.logout();
  if (mounted) {
    // Navigate to login screen and remove all other screens from the stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
 /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('My Profile')),
      appBar:AppBar(title: Text(AppLocalizations.of(context)!.profileTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 20),
                    Text('Mobile Number: $_mobileNumber', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date of Birth'),
                      subtitle: Text(_selectedDate == null
                          ? 'Not set'
                          : DateFormat.yMMMd().format(_selectedDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _allergiesController,
                      decoration: const InputDecoration(labelText: 'Known Allergies'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: const Text('Save Changes'),
                    ),
const SizedBox(height: 20),
const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
Consumer<LocaleProvider>(
  builder: (context, provider, child) {
    return DropdownButton<Locale>(
      value: provider.locale ?? const Locale('en'),
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: Locale('en'), child: Text('English')),
        DropdownMenuItem(value: Locale('hi'), child: Text('हिंदी (Hindi)')),
        DropdownMenuItem(value: Locale('gu'), child: Text('ગુજરાતી (Gujarati)')),
      ],
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          provider.setLocale(newLocale);
        }
      },
    );
  },
),
const SizedBox(height: 40),
ElevatedButton(
  onPressed: _isLoading ? null : _saveProfile,
  // Use the localized string for the button text
  child: Text(AppLocalizations.of(context)!.saveChanges),
),

                    const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: _logout,
                  ),
                  ],
                ),
              ),
            ),
    );
  }*/

  @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!; // Helper variable for translations
 final settingsProvider = Provider.of<SettingsProvider>(context);
  return Scaffold(
    appBar: AppBar(title: Text(l10n.profileTitle)),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- NEW: Profile Picture Avatar ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageUrl != null
                                ? NetworkImage(ApiService.baseUrlForImages + _imageUrl!)
                                : null,
                            child: _imageUrl == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _pickAndUploadImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.fullName),
                    validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 20),
                  Text('${l10n.mobileNumber}: $_mobileNumber', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.dateOfBirth),
                    subtitle: Text(_selectedDate == null ? 'Not set' : DateFormat.yMMMd().format(_selectedDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: InputDecoration(labelText: l10n.knownAllergies),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.language, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Consumer<SettingsProvider>(
                    builder: (context, provider, child) {
                      return DropdownButton<Locale>(
                       value: provider.locale,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: Locale('en'), child: Text('English')),
                          DropdownMenuItem(value: Locale('hi'), child: Text('हिंदी (Hindi)')),
                          DropdownMenuItem(value: Locale('gu'), child: Text('ગુજરાતી (Gujarati)')),
                        ],
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) provider.setLocale(newLocale);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                    Text("Appearance", style: Theme.of(context).textTheme.titleMedium),
                    // NEW: The Theme Switcher
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.wb_sunny)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.nightlight_round)),
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings)),
                      ],
                      selected: {settingsProvider.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        settingsProvider.setThemeMode(newSelection.first);
                      },
                    ),

                  const SizedBox(height: 40),
                  // The one and only "Save" button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: Text(l10n.saveChanges),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.logOut),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 16),
                    // TEMPORARY BUTTON FOR TESTING
                    /*ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        throw Exception('This is a test crash!');
                      },
                      child: const Text('Test Crash'),
                    ),*/
                ],
              ),
            ),
          ),
  );
}
}