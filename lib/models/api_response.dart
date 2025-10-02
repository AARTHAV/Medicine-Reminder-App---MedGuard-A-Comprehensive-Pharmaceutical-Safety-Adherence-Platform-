// lib/models/api_response.dart

class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data; // For responses that return data

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });
}