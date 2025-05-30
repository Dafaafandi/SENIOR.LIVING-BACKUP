// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import '../models/health_record.dart'; // Pastikan path ini benar
import '../models/user_model.dart'; // Anda mungkin perlu model User
import '../models/hospital_visit.dart'; // <-- Tambahkan import ini

class ApiService {
  // Make all static constants const
  static const String _serverBaseUrl = 'http://18.140.38.247';
  static const String _publicApiBaseUrl = '$_serverBaseUrl/api';
  static const String _protectedApiBaseUrl = '$_serverBaseUrl/api/admin';
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Add const constructor
  const ApiService();

  // Fungsi untuk menyimpan token dan data user
  Future<void> _saveAuthData(
      String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userDataKey,
        jsonEncode(userData)); // Simpan data user sebagai JSON String
  }

  // Fungsi untuk mengambil token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Fungsi untuk mengambil data user
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Fungsi untuk menghapus token dan data user (logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    // Anda juga bisa memanggil endpoint logout API di sini jika ada
  }

  Future<String> _getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = 'UnknownDevice';
    try {
      if (kIsWeb) {
        deviceName = 'WebApp';
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model ?? 'AndroidDevice';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.utsname.machine ?? 'iOSDevice';
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceName = windowsInfo.computerName;
      }
    } catch (e) {
      print("Error getting device info: $e");
    }
    return deviceName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      String deviceName = await _getDeviceName();

      final response = await http.post(
        Uri.parse('$_publicApiBaseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': deviceName,
        }),
      );

      print(
          'DEBUG Login Request URL: ${Uri.parse('$_publicApiBaseUrl/login')}');
      print('DEBUG Login Request Device: $deviceName');
      print('DEBUG Login Response Status: ${response.statusCode}');
      print('DEBUG Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('token') &&
            responseData.containsKey('user')) {
          await _saveAuthData(responseData['token'], responseData['user']);
          final UserModel user =
              UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
          return {
            'success': true,
            'user': user.toJson(), // Convert back to map for consistency
            'message': responseData['message'] ?? 'Login berhasil'
          };
        }
        return {'success': false, 'message': 'Format respons tidak valid'};
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Login gagal'
      };
    } catch (e) {
      print('DEBUG Login Exception: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      String deviceName = await _getDeviceName();

      final response = await http.post(
        Uri.parse('$_publicApiBaseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'device_name': deviceName
        }),
      );

      print(
          'DEBUG Register Request URL: ${Uri.parse('$_publicApiBaseUrl/register')}');
      print('DEBUG Register Request Body: ${jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
            'device_name': deviceName
          })}');
      print('DEBUG Register Response Status: ${response.statusCode}');
      print('DEBUG Register Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('token') &&
            responseData.containsKey('user')) {
          await _saveAuthData(responseData['token'], responseData['user']);
          return {
            'success': true,
            'user': responseData['user'],
            'message': responseData['message'] ?? 'Registrasi berhasil'
          };
        }
        return {
          'success': true,
          'message': responseData['message'] ?? 'Registrasi berhasil'
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Registrasi gagal';

        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData.containsKey('errors')) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage =
              errors.entries.map((e) => '${e.key}: ${e.value[0]}').join('\n');
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error during registration: $e');
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> simpanCatatanKesehatan({
    required int patientId,
    required DateTime tanggalPemeriksaan,
    String? tekananDarah,
    String? spo2,
    String? gulaDarah,
    String? kolesterol,
    String? asamUrat,
    String? catatan,
  }) async {
    final String? token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      // Format the date to match API expectations (YYYY-MM-DD)
      final formattedDate = DateFormat('yyyy-MM-dd').format(tanggalPemeriksaan);

      final Map<String, dynamic> requestBody = {
        'patient_id': patientId,
        'checkup_date': formattedDate,
      };

      // Only add non-null values to the request body with correct field names
      if (tekananDarah?.isNotEmpty ?? false) {
        requestBody['blood_pressure'] = tekananDarah;
      }
      if (spo2?.isNotEmpty ?? false) {
        requestBody['oxygen_saturation'] = int.parse(spo2!);
      }
      if (gulaDarah?.isNotEmpty ?? false) {
        requestBody['blood_sugar'] =
            int.parse(gulaDarah!); // Changed from blood_sugar_level
      }
      if (kolesterol?.isNotEmpty ?? false) {
        requestBody['cholesterol'] =
            int.parse(kolesterol!); // Changed from cholesterol_level
      }
      if (asamUrat?.isNotEmpty ?? false) {
        requestBody['uric_acid'] =
            double.parse(asamUrat!); // Changed from uric_acid_level
      }
      if (catatan?.isNotEmpty ?? false) {
        requestBody['notes'] = catatan;
      }

      print('DEBUG - Sending request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_protectedApiBaseUrl/checkups'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseBody = jsonDecode(response.body);
      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Berhasil disimpan',
          'data': responseBody['data'],
        };
      } else {
        String errorMessage = responseBody['message'] ?? 'Gagal menyimpan data';
        if (responseBody.containsKey('errors')) {
          final errors = responseBody['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.expand((e) => e as List).join('\n');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Error creating health record: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> updateCatatanKesehatan({
    required String recordId,
    required int patientId,
    required DateTime tanggalPemeriksaan,
    String? tekananDarah,
    String? spo2,
    String? gulaDarah,
    String? kolesterol,
    String? asamUrat,
    String? catatan,
  }) async {
    final String? token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      final Map<String, dynamic> requestBody = {
        'checkup_date': DateFormat('yyyy-MM-dd').format(tanggalPemeriksaan),
      };

      // Only add non-null values with correct field names
      if (tekananDarah?.isNotEmpty ?? false) {
        requestBody['blood_pressure'] = tekananDarah;
      }
      if (spo2?.isNotEmpty ?? false) {
        requestBody['oxygen_saturation'] = int.parse(spo2!);
      }
      if (gulaDarah?.isNotEmpty ?? false) {
        requestBody['blood_sugar'] = int.parse(gulaDarah!);
      }
      if (kolesterol?.isNotEmpty ?? false) {
        requestBody['cholesterol'] = int.parse(kolesterol!);
      }
      if (asamUrat?.isNotEmpty ?? false) {
        requestBody['uric_acid'] = double.parse(asamUrat!);
      }
      if (catatan?.isNotEmpty ?? false) {
        requestBody['notes'] = catatan;
      }

      print('DEBUG - Sending UPDATE request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$_protectedApiBaseUrl/checkups/$recordId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseBody = jsonDecode(response.body);
      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Berhasil diperbarui',
          'data': responseBody['data'],
        };
      } else {
        String errorMessage =
            responseBody['message'] ?? 'Gagal memperbarui data';
        if (responseBody.containsKey('errors')) {
          final errors = responseBody['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.expand((e) => e as List).join('\n');
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Error updating health record: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  Future<List<HealthRecord>?> getCatatanKesehatan(
      {required int patientId}) async {
    final String? token = await getToken();
    if (token == null) return null;

    final apiUrl = '$_protectedApiBaseUrl/checkups?patient_id=$patientId';
    print("DEBUG: Fetching health records from $apiUrl");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['data'] != null && jsonResponse['data'] is List) {
          List<dynamic> listData = jsonResponse['data'];
          List<HealthRecord> records = listData.map((data) {
            return HealthRecord(
              id: data['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              date: DateTime.parse(data['checkup_date']),
              bloodPressure: data['blood_pressure'],
              // Sesuaikan parsing dengan tipe data dari API jika berbeda
              spo2: data['oxygen_saturation'] != null
                  ? int.tryParse(data['oxygen_saturation'].toString())
                  : null,
              bloodSugar: data['blood_sugar_level'] != null ||
                      data['blood_sugar'] != null
                  ? int.tryParse(
                      (data['blood_sugar_level'] ?? data['blood_sugar'])
                          .toString())
                  : null,
              cholesterol: data['cholesterol_level'] != null ||
                      data['cholesterol'] != null
                  ? int.tryParse(
                      (data['cholesterol_level'] ?? data['cholesterol'])
                          .toString())
                  : null,
              uricAcid: data['uric_acid_level'] != null ||
                      data['uric_acid'] != null
                  ? double.tryParse(
                      (data['uric_acid_level'] ?? data['uric_acid']).toString())
                  : null,
              notes: data['notes'],
            );
          }).toList();
          return records;
        }
        print(
            "Format response tidak sesuai atau data kosong: ${response.body}");
        return [];
      } else {
        print('Gagal mengambil data: ${response.statusCode}');
        print('Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error saat getCatatanKesehatan: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> deleteCatatanKesehatan(String recordId) async {
    final String? token = await getToken();
    if (token == null)
      return {'success': false, 'message': 'Token tidak ditemukan'};

    final apiUrl = '$_protectedApiBaseUrl/checkups/$recordId';
    print("DEBUG: Deleting health record from $apiUrl");

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Map<String, dynamic>? responseBody;
        if (response.body.isNotEmpty) {
          responseBody = jsonDecode(response.body);
        }
        return {
          'success': true,
          'message': responseBody?['message'] ?? 'Catatan berhasil dihapus',
          'data': {'id': recordId}
        };
      } else {
        String errorMessage = 'Gagal menghapus catatan dari server.';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (_) {
            // Keep default error message if body isn't valid JSON
          }
        }
        print(
            'Delete failed. Status: ${response.statusCode}. Body: ${response.body}');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error deleting health record: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method baru untuk mengambil riwayat kontrol
  Future<List<HospitalVisit>> getHospitalVisits(int patientId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final url = Uri.parse(
        '$_protectedApiBaseUrl/hospital-visits?patient_id=$patientId');
    print("DEBUG: Fetching hospital visits from $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("DEBUG: Hospital visits response status: ${response.statusCode}");
    print("DEBUG: Hospital visits response body: ${response.body}");

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);

      // Handle Rupadana pagination response
      final List<dynamic> data = decodedBody is Map
          ? (decodedBody['data'] as List? ?? [])
          : (decodedBody as List? ?? []);

      final hospitalVisits = data
          .map<HospitalVisit>(
              (item) => HospitalVisit.fromJson(item as Map<String, dynamic>))
          .toList();

      print("DEBUG: Parsed ${hospitalVisits.length} hospital visits.");
      if (hospitalVisits.isNotEmpty) {
        print(
            "DEBUG: First parsed hospital visit: ID ${hospitalVisits.first.id}, Hospital: ${hospitalVisits.first.hospitalName}");
      }

      return hospitalVisits;
    } else {
      print('Failed to load hospital visits: ${response.body}');
      throw Exception('Failed to load hospital visits');
    }
  }

  // Method baru untuk menambah riwayat kontrol
  Future<HospitalVisit> addHospitalVisit(HospitalVisit hospitalVisit) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final url = Uri.parse('$_protectedApiBaseUrl/hospital-visits');
    print("DEBUG: Adding hospital visit to $url");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(hospitalVisit.toJson()),
    );

    print("DEBUG: Add hospital visit response status: ${response.statusCode}");
    print("DEBUG: Add hospital visit response body: ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final data = responseData is Map
          ? (responseData['data'] ?? responseData)
          : responseData;
      return HospitalVisit.fromJson(data as Map<String, dynamic>);
    } else {
      print('Failed to add hospital visit: ${response.body}');
      throw Exception('Failed to add hospital visit');
    }
  }
}
