import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String registerEndpoint = '/api/auth/register/';
  static const String loginEndpoint = '/api/auth/login/';
  static const String classesEndpoint = '/api/classes/';
  static const String joinClassEndpoint = '/api/classes/join/';

  // JWT Token management
  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // JWT Token decoding to extract user role
  static String? decodeUserRole(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode payload (second part)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      final payloadMap = jsonDecode(decoded);
      return payloadMap['role'];
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getUserRole() async {
    final token = await getAccessToken();
    if (token == null) return null;
    return decodeUserRole(token);
  }

  // Helper method to get authenticated headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl + registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Registrasi gagal';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Login user
  /// [email] - User's email address
  /// [password] - User's password
  ///
  /// Returns a Map containing access and refresh tokens on success
  /// Throws an exception on failure
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl + loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Save tokens
        if (responseData.containsKey('access') &&
            responseData.containsKey('refresh')) {
          await saveTokens(responseData['access'], responseData['refresh']);
        }
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Login gagal';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Create a new class (Teacher only)
  /// [name] - Class name
  /// [description] - Class description
  ///
  /// Returns a Map containing the class data on success
  /// Throws an exception on failure
  static Future<Map<String, dynamic>> createClass({
    required String name,
    required String description,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl + classesEndpoint),
        headers: headers,
        body: jsonEncode({'name': name, 'description': description}),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal membuat kelas';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Get list of classes for the current teacher
  ///
  /// Returns a List of class data on success
  /// Throws an exception on failure
  static Future<List<Map<String, dynamic>>> getMyClasses() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(baseUrl + classesEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          return [];
        }
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal mengambil daftar kelas';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Create a new material for a class (Teacher only)
  /// [classId] - ID of the class
  /// [title] - Material title
  /// [content] - Material content
  ///
  /// Returns a Map containing the material data on success
  /// Throws an exception on failure
  static Future<Map<String, dynamic>> createMaterial({
    required int classId,
    required String title,
    required String content,
  }) async {
    print('API: Creating material for class $classId with title: $title');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$classesEndpoint$classId/materials/'),
        headers: headers,
        body: jsonEncode({'title': title, 'content': content}),
      );

      print('API: Response status: ${response.statusCode}');
      print('API: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('API: Material created successfully: $responseData');
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal menambah materi';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        print('API: Error creating material: $errorMessage');
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('API: Exception in createMaterial: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Get materials for a specific class
  /// [classId] - ID of the class
  ///
  /// Returns a List of material data on success
  /// Throws an exception on failure
  static Future<List<Map<String, dynamic>>> getClassMaterials(
    int classId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$classesEndpoint$classId/materials/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          return [];
        }
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal mengambil materi kelas';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Create a new assignment for a class (Teacher only)
  /// [classId] - ID of the class
  /// [title] - Assignment title
  /// [description] - Assignment description
  /// [deadline] - Assignment deadline
  ///
  /// Returns a Map containing the assignment data on success
  /// Throws an exception on failure
  static Future<Map<String, dynamic>> createAssignment({
    required int classId,
    required String title,
    required String description,
    required String deadline,
  }) async {
    print('API: Creating assignment for class $classId with title: $title');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$classesEndpoint$classId/assignments/'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'deadline': deadline,
        }),
      );

      print('API: Response status: ${response.statusCode}');
      print('API: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('API: Assignment created successfully: $responseData');
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal membuat tugas';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        print('API: Error creating assignment: $errorMessage');
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('API: Exception in createAssignment: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Get assignments for a specific class
  /// [classId] - ID of the class
  ///
  /// Returns a List of assignment data on success
  /// Throws an exception on failure
  static Future<List<Map<String, dynamic>>> getClassAssignments(
    int classId,
  ) async {
    print('API: Loading assignments for class $classId');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$classesEndpoint$classId/assignments/'),
        headers: headers,
      );

      print('API: Response status: ${response.statusCode}');
      print('API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          print('API: Loaded ${responseData.length} assignments');
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          return [];
        }
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal mengambil daftar tugas';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        print('API: Error loading assignments: $errorMessage');
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('API: Exception in getClassAssignments: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Submit an assignment (Student only)
  /// [assignmentId] - ID of the assignment
  /// [answer] - Student's answer
  ///
  /// Returns a Map containing success message and submission data on success
  /// Throws an exception on failure
  static Future<Map<String, dynamic>> submitAssignment({
    required int assignmentId,
    required String answer,
  }) async {
    print('API: Submitting assignment $assignmentId');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/$assignmentId/submit/'),
        headers: headers,
        body: jsonEncode({'answer': answer}),
      );

      print('API: Response status: ${response.statusCode}');
      print('API: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('API: Assignment submitted successfully: $responseData');
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal mengumpulkan tugas';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        print('API: Error submitting assignment: $errorMessage');
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('API: Exception in submitAssignment: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Get submissions for a specific assignment (Teacher only)
  /// [assignmentId] - ID of the assignment
  ///
  /// Returns a List of submission data on success
  /// Throws an exception on failure
  static Future<List<Map<String, dynamic>>> getAssignmentSubmissions(
    int assignmentId,
  ) async {
    print('API: Loading submissions for assignment $assignmentId');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/assignments/$assignmentId/submissions/'),
        headers: headers,
      );

      print('API: Response status: ${response.statusCode}');
      print('API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          print('API: Loaded ${responseData.length} submissions');
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          return [];
        }
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal mengambil daftar jawaban';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        print('API: Error loading submissions: $errorMessage');
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('API: Exception in getAssignmentSubmissions: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Get class insights/statistics (Teacher only)
  /// [classId] - ID of the class
  ///
  /// Returns a Map containing class insights on success
  /// Throws an exception on failure
  static Future<Map<String, dynamic>> getClassInsight(int classId) async {
    print('API: Loading insights for class $classId');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$classesEndpoint$classId/insight/'),
        headers: headers,
      );

      print('API: Response status: ${response.statusCode}');
      print('API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('API: Class insights loaded successfully: $responseData');
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal mengambil insight kelas';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        print('API: Error loading insights: $errorMessage');
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      print('API: Exception in getClassInsight: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Join a class using class code (Student only)
  /// [code] - Class code to join
  ///
  /// Returns a Map containing success message on success
  /// Throws an exception on failure
  static Future<Map<String, dynamic>> joinClass(String code) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl + joinClassEndpoint),
        headers: headers,
        body: jsonEncode({
          'code': code.toUpperCase(), // Auto-convert to uppercase
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal bergabung ke kelas';

        // Handle specific error cases
        if (errorData.containsKey('code') && errorData['code'] is List) {
          errorMessage = errorData['code'][0];
        } else if (errorData.containsKey('non_field_errors') &&
            errorData['non_field_errors'] is List) {
          errorMessage = errorData['non_field_errors'][0];
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'];
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Test connectivity to the API server
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode < 500; // Consider any 5xx error as unreachable
    } catch (e) {
      return false;
    }
  }
}
