// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:io'; // Required for SocketException
import 'package:medguard/models/api_response.dart';
import 'package:flutter/material.dart';

class ApiService {
  // --- Singleton Setup ---
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();
  // --- End Singleton Setup ---

  // IMPORTANT: Replace with your actual API's base URL.
  // Use http://10.0.2.2:PORT for Android Emulator if API is on localhost.
  static const String _baseUrl = "http://192.168.1.12:8008/api"; 
  //static const String _baseUrl = "https://medguard.loca.lt/api";
 
  //static const String _baseUrl = "https://4f684e7ca3f2.ngrok-free.app/api"; 
  //static const String _baseUrl = "https://localhost:44354/api"; 
  static const String baseUrlForImages = "http://192.168.1.12:8008";
  // Calls the send-otp endpoint
  /*Future<bool> sendOtp(String mobileNumber) async {
    final url = Uri.parse('$_baseUrl/auth/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobileNumber': mobileNumber}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print(e); // For debugging
      return false;
    }
  }*/
  Locale _currentLocale = const Locale('en'); // Add a property to hold the locale

  // Method for the provider to update the locale
  void setCurrentLocale(Locale locale) {
    _currentLocale = locale;
  }
  var logger = Logger();

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final langCode = _currentLocale.languageCode;
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Accept-Language': langCode,
    };
  }
//27-09-2025
  /*Future<bool> sendOtp(String mobileNumber) async {
  final url = Uri.parse('$_baseUrl/auth/send-otp');
  logger.i('Calling API at: $url'); // Let's also print the URL to be sure

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'mobileNumber': mobileNumber}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['otp']; // Return the OTP string
      //logger.i('API call successful!');
      //return true;
    } else {
      // This block will run if the server returns an error like 400, 404, or 500
      logger.e('--- API REQUEST FAILED ---');
      logger.e('Status Code: ${response.statusCode}');
      logger.e('Response Body: ${response.body}');
      return false;
    }
  } catch (e) {
    // This block will run if there's a network error (e.g., can't connect to ngrok)
    logger.e('--- API CALL FAILED WITH EXCEPTION ---');
    logger.e('Error: $e');
    return false;
  }
}*/

// In lib/api_service.dart

// The method now returns our ApiResponse class for better error handling
// In lib/api_service.dart

Future<ApiResponse> sendOtp(String mobileNumber) async {
  final url = Uri.parse('$_baseUrl/auth/send-otp');
  try {
    final response = await http.post(
      url,
      // Use a simple, non-authenticated header for this public request
      headers: {
        'Content-Type': 'application/json'
      },
      body: json.encode({'mobileNumber': mobileNumber}),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      // Success! Return the OTP for testing purposes.
      return ApiResponse(success: true, data: data['otp']);
    } else {
      // If the API returns its own error message, display it
      return ApiResponse(success: false, message: data.toString());
    }
  } on SocketException {
    // Handle no internet connection
    return ApiResponse(success: false, message: 'Please check your internet connection.');
  } catch (e) {
    // Handle any other unexpected error
    return ApiResponse(success: false, message: 'An unexpected error occurred.');
  }
}
  // Calls the verify-otp endpoint
  /*Future<Map<String, dynamic>?> verifyOtp(String mobileNumber, String otp) async {
    final url = Uri.parse('$_baseUrl/auth/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobileNumber': mobileNumber, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Returns user profile
      } else {
        return null; // OTP was incorrect or expired
      }
    } catch (e) {
      logger.e(e); // For debugging
      return null;
    }
  }*/
  // In lib/api_service.dart
Future<ApiResponse> verifyOtp(String mobileNumber, String otp) async {
  final url = Uri.parse('$_baseUrl/auth/verify-otp');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'mobileNumber': mobileNumber, 'otp': otp}),
    );
    
    if (response.statusCode == 200) {
      return ApiResponse(success: true, data: json.decode(response.body));
    } else {
      return ApiResponse(success: false, message: 'Invalid OTP. Please try again.');
    }
  } catch (e) {
    return ApiResponse(success: false, message: 'An error occurred. Please check your connection.');
  }
}

  // lib/api_service.dart
// Add this new method inside the ApiService class

 /* Future<List<dynamic>> getDashboardMedicines() async {
      final token = await getToken();
       if (token == null) return [];
    final url = Uri.parse('$_baseUrl/medicines/dashboard');
 
    try {
         final response = await http.get(url, headers: {
       'Authorization': 'Bearer $token',
        });
      // We will add auth headers here in the next step
      //final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        return []; // Return empty list on failure
      }
    } catch (e) {
      logger.e(e); // For debugging
      return [];
    }
  }
*/

// In lib/api_service.dart

// In lib/api_service.dart

Future<List<dynamic>> getDashboardData() async {
  final token = await getToken();
  if (token == null) return [];
 final headers = await _getHeaders();
  final url = Uri.parse('$_baseUrl/dashboard');
  try {
    //final response = await http.get(
      //url,
      //headers: {'Authorization': 'Bearer $token'},
      //final response = await http.get(url, headers: headers);
       final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decodedJson = json.decode(response.body);

      // NEW, SAFER LOGIC:
      // First, check if the decoded response is a Map (which would be our error object)
      if (decodedJson is Map<String, dynamic> && decodedJson.containsKey('error')) {
        logger.e("Server returned an error: ${decodedJson['error']}");
        return [];
      } 
      // Otherwise, if it's a List, it's our successful data
      else if (decodedJson is List) {
        return decodedJson;
      }
    } else {
      logger.e('Dashboard API failed with status code: ${response.statusCode}');
    }
  } catch (e) {
    logger.e('Error getting dashboard data: $e');
  }
  // Return an empty list for any failure case
  return [];
}
  Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('authToken', token);
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('authToken');
}
// Add the NEW method for adding medicine
/*Future<bool> addMedicineFromScan(int medicineId, int quantity) async {
  final token = await getToken();
  print('--- [Flutter] Sending Token ---');
  print(token);
  if (token == null) return false;

  final url = Uri.parse('$_baseUrl/medicines/add');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({'MedicineID': medicineId, 'Quantity': quantity}),
  );
  return response.statusCode == 200;
}*/

// In lib/api_service.dart
/*Future<int?> addMedicineFromScan(int medicineId, int quantity) async {
  final token = await getToken();
  if (token == null) return null;

  final url = Uri.parse('$_baseUrl/medicines/add');
  
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'MedicineID': medicineId, 'Quantity': quantity}),
    );
    
    if (response.statusCode == 200) {
       logger.i('--- API Success Response Body ---');
       logger.i(response.body);
      final data = json.decode(response.body);
      
      // NEW: Check if the server sent back an error payload
      if (data['error'] != null) {
        logger.i('--- Add Medicine API FAILED (Reported by Server) ---');
        logger.i('Server Error: ${data['error']}');
        logger.i('Stack Trace: ${data['stackTrace']}');
        return null;
      }
      
      return data['userMedicineId'];
    } else {
      logger.e('--- Add Medicine API FAILED ---');
      logger.e('Status Code: ${response.statusCode}');
      logger.e('Response Body: ${response.body}');
      return null;
    }
  } catch (e) {
      logger.e('--- API CALL FAILED WITH EXCEPTION ---');
      logger.e('Error: $e');
      return null;
  }
}*/
// In lib/api_service.dart

// The method now returns our ApiResponse class for better error handling
Future<ApiResponse> addMedicineFromScan(Map<String, dynamic> medicineData) async {
  final token = await getToken();
  if (token == null) {
    return ApiResponse(success: false, message: 'Not authenticated.');
  }

  final url = Uri.parse('$_baseUrl/medicines/add');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(medicineData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        // The API returned a specific error message (e.g., "Already scanned")
        return ApiResponse(success: false, message: data['error']);
      } else {
        // Success! Return the data payload.
        return ApiResponse(success: true, data: data);
      }
    } else {
      return ApiResponse(success: false, message: 'A server error occurred.');
    }
  } on SocketException {
    return ApiResponse(success: false, message: 'Please check your internet connection.');
  } catch (e) {
    return ApiResponse(success: false, message: 'An unexpected error occurred.');
  }
}
// ADD THIS NEW METHOD to the ApiService class
/*Future<bool> setSchedule(Map<String, dynamic> scheduleData) async {
  final token = await getToken();
  if (token == null) return false;

  final url = Uri.parse('$_baseUrl/schedules');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(scheduleData),
  );
  return response.statusCode == 200;
}*/

// In lib/api_service.dart

// In lib/api_service.dart

Future<ApiResponse> setSchedule(Map<String, dynamic> scheduleData) async {
  final token = await getToken();
  if (token == null) {
    return ApiResponse(success: false, message: 'Not authenticated.');
  }

  final url = Uri.parse('$_baseUrl/schedules');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(scheduleData),
    );

    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: 'Schedule saved successfully!');
    } else {
      // Handle server-side errors
      return ApiResponse(success: false, message: 'A server error occurred. Please try again later.');
    }
  } on SocketException {
    // Handle network errors (no internet)
    return ApiResponse(success: false, message: 'Please check your internet connection.');
  } catch (e) {
    // Handle any other unexpected errors
    logger.e('Error in setSchedule: $e');
    return ApiResponse(success: false, message: 'An unexpected error occurred.');
  }
}
// In lib/api_service.dart

// ADD THIS NEW METHOD
Future<void> saveFcmToken(String fcmToken) async {
  final token = await getToken();
  if (token == null) return;

  final url = Uri.parse('$_baseUrl/auth/fcm-token');
  try {
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'token': fcmToken}),
    );
  } catch (e) {
    logger.e('Failed to save FCM token: $e');
  }
}
// In lib/api_service.dart

Future<bool> markDoseAsTaken(int logId) async {
  final token = await getToken();
  if (token == null) return false;

  // Note the URL structure with the logId in the path
  final url = Uri.parse('$_baseUrl/doselogs/$logId/take');
   logger.e("---[ApiService]: Calling POST $url");

  try {
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    logger.e("---[ApiService]: Received status code: ${response.statusCode}");
     if (response.body.isNotEmpty) {
      logger.e("---[ApiService]: Received response body: ${response.body}");
    }
    return response.statusCode == 200;
  } catch (e) {
    //print('---[ApiService]: Error marking dose as taken: $e');
    logger.e('Error marking dose as taken: $e');
    return false;
  }
}
// In lib/api_service.dart

Future<bool> deleteMedicine(int userMedicineId) async {
  final token = await getToken();
  if (token == null) return false;

  final url = Uri.parse('$_baseUrl/medicines/$userMedicineId');

  try {
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  } catch (e) {
    logger.e('Error deleting medicine: $e');
    return false;
  }
}
// In lib/api_service.dart

Future<Map<String, dynamic>?> getProfile() async {
  final token = await getToken();
  if (token == null) return null;

  final url = Uri.parse('$_baseUrl/profile');
  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) {
    logger.e('Error getting profile: $e');
  }
  return null;
}
// In lib/api_service.dart

Future<ApiResponse> updateProfile(Map<String, dynamic> profileData) async {
  final token = await getToken();
  if (token == null) return ApiResponse(success: false, message: 'Not authenticated.');

  final url = Uri.parse('$_baseUrl/profile');
  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(profileData),
    );

    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: 'Profile updated successfully!');
    } else {
      // Return the error from the server if one exists
      final data = json.decode(response.body);
      return ApiResponse(success: false, message: data['error'] ?? 'A server error occurred.');
    }
  } on SocketException {
    return ApiResponse(success: false, message: 'Please check your internet connection.');
  } catch (e) {
    return ApiResponse(success: false, message: 'An unexpected error occurred.');
  }
}
/*Future<bool> updateProfile(Map<String, dynamic> profileData) async {
  final token = await getToken();
  if (token == null) return false;

  final url = Uri.parse('$_baseUrl/profile');
  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(profileData),
    );
    return response.statusCode == 200;
  } catch (e) {
    logger.e('Error updating profile: $e');
    return false;
  }
}*/
// In lib/api_service.dart

Future<List<dynamic>> getDoseHistory(DateTime startDate, DateTime endDate) async {
  final token = await getToken();
   final headers = await _getHeaders();
  if (token == null) return [];

  // Format dates to "YYYY-MM-DD" for the API query
  final String start = DateFormat('yyyy-MM-dd').format(startDate);
  final String end = DateFormat('yyyy-MM-dd').format(endDate);

  final url = Uri.parse('$_baseUrl/doselogs/history?startDate=$start&endDate=$end');

  try {
    //final response = await http.get(
     // url,
     // headers: {'Authorization': 'Bearer $token'},
    //);
     final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
  } catch (e) {
    logger.e('Error getting dose history: $e');
  }
  return [];
}
// In lib/api_service.dart

Future<bool> snoozeDose(int logId, int minutes) async {
  final token = await getToken();
  if (token == null) return false;

  final url = Uri.parse('$_baseUrl/doselogs/$logId/snooze');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'snoozeMinutes': minutes}),
    );
    return response.statusCode == 200;
  } catch (e) {
    logger.e('Error snoozing dose: $e');
    return false;
  }
}
// In lib/api_service.dart
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('authToken');
}
// In lib/api_service.dart

// The 'http' package needs to be imported with a name for this to work
// At the top of your file, make sure it says: import 'package:http/http.dart' as http;

// In lib/api_service.dart

Future<String?> uploadProfileImage(String imagePath) async {
  final token = await getToken();
  if (token == null) return null;

  final url = Uri.parse('$_baseUrl/profile/image');
  try {
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'file', // This key must match what the server expects
      imagePath,
    ));

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['imageUrl'];
    } else {
      // NEW: Log the error response from the server
      logger.i('--- Image Upload API FAILED ---');
      logger.i('Status Code: ${response.statusCode}');
      logger.i('Response Body: $responseBody');
      return null;
    }
  } catch (e) {
    logger.e('Error uploading profile image: $e');
    return null;
  }
}
// In lib/api_service.dart

Future<bool> updateStockThreshold(int userMedicineId, int threshold) async {
  final token = await getToken();
  if (token == null) return false;

  final url = Uri.parse('$_baseUrl/medicines/$userMedicineId/threshold');
  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'threshold': threshold}),
    );
    return response.statusCode == 200;
  } catch (e) {
    logger.e('Error updating threshold: $e');
    return false;
  }
}
// In lib/api_service.dart

Future<Map<String, dynamic>?> getMedicineDetails(int userMedicineId) async {
  final headers = await _getHeaders();
  final url = Uri.parse('$_baseUrl/medicines/$userMedicineId/details');

  try {
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) {
    logger.e('Error getting medicine details: $e');
  }
  return null;
}
// In lib/api_service.dart

Future<List<dynamic>> getUserBatches() async {
  final headers = await _getHeaders();
  final url = Uri.parse('$_baseUrl/inventory/batches');
  try {
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
  } catch (e) {
    logger.e('Error getting user batches: $e');
  }
  return [];
}

Future<bool> markBatchForReturn(int batchId) async {
  final headers = await _getHeaders();
  final url = Uri.parse('$_baseUrl/inventory/batches/$batchId/mark-for-return');
  try {
    final response = await http.post(url, headers: headers);
    return response.statusCode == 200;
  } catch (e) {
    logger.e('Error marking batch for return: $e');
    return false;
  }
}
// In lib/api_service.dart

// This fetches the new, detailed list of today's individual doses
Future<List<dynamic>> getTodaysDoses() async {
  final headers = await _getHeaders();
  final url = Uri.parse('$_baseUrl/dashboard/today');
  try {
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
  } catch (e) {
    logger.i('Error getting today\'s doses: $e');
  }
  return [];
}

// This is called when the user manually taps the "Take" button on the dashboard
Future<bool> takeDoseManually(int userMedicineId, DateTime scheduledTime) async {
  final headers = await _getHeaders();
  final url = Uri.parse('$_baseUrl/doselogs/manual-take');
  try {
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'userMedicineID': userMedicineId,
        'scheduledTime': scheduledTime.toIso8601String(),
      }),
    );
    return response.statusCode == 200;
  } catch (e) {
    logger.i('Error taking dose manually: $e');
    return false;
  }
}
}