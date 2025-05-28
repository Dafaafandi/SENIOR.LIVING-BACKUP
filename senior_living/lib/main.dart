// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:senior_living/repository.dart'; // Komentari jika tidak digunakan
// import 'package:senior_living/model.dart';     // Komentari jika tidak digunakan
import 'screens/opening_screen.dart';
import 'package:senior_living/screens/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/success_screen.dart';
import 'screens/schedule/schedule_screen.dart';
// import 'screens/health/health_record_screen.dart'; // Tidak digunakan di routes
import 'screens/health/health_screen.dart';
import 'screens/history/riwayat_kontrol_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/settings/settings_screen.dart'; // Pastikan file ini ada jika dirujuk
import 'models/schedule_item.dart';
import 'models/health_record.dart';
import 'models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk memuat patientId saat init

const String healthRecordsBoxName = 'health_records';
const String schedulesBoxName = 'schedules';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Hive.initFlutter();
  Hive.registerAdapter(ScheduleItemAdapter());
  Hive.registerAdapter(HealthRecordAdapter());
  // Hive.registerAdapter(UserModelAdapter()); // Jika Anda membuat adapter untuk UserModel

  await Hive.openBox<ScheduleItem>(schedulesBoxName);
  await Hive.openBox<HealthRecord>(healthRecordsBoxName);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? currentPatientId;

  @override
  void initState() {
    super.initState();
    _loadCurrentPatientId(); 
  }

  Future<void> _loadCurrentPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('patient_id')) {
      setState(() {
        currentPatientId = prefs.getInt('patient_id');
        print("DEBUG: Loaded currentPatientId from SharedPreferences: $currentPatientId");
      });
    }
  }

  void updateCurrentPatientId(int? patientId) async {
    setState(() {
      currentPatientId = patientId;
    });
    final prefs = await SharedPreferences.getInstance();
    if (patientId != null) {
      await prefs.setInt('patient_id', patientId);
      print("DEBUG: Saved currentPatientId to SharedPreferences: $patientId");
    } else {
      await prefs.remove('patient_id');
      print("DEBUG: Removed currentPatientId from SharedPreferences");
    }
  }

  // Helper function for patientId parsing
  int? _parsePatientId(dynamic value, String routeName) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        print("Warning: Could not parse patientId string '$value' to int for route $routeName");
      }
      return parsed;
    }
    print("Warning: Unexpected patientId type: ${value.runtimeType} for route $routeName. Value: $value");
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Senior Living',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', '')],
      locale: const Locale('id', 'ID'),
      initialRoute: '/opening',
      routes: {
        '/opening': (context) => const OpeningScreen(),
        '/login': (context) => LoginScreen(
              onLoginSuccess: (UserModel user, int? patientIdFromLogin) {
                updateCurrentPatientId(patientIdFromLogin);
              },
            ),
        '/create-account': (context) => const CreateAccountScreen(),
        '/success': (context) => const SuccessScreen(),
        '/home_page': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          
          final String userName = arguments?['name'] as String? ?? 'Pengguna';
          final int userAge = (arguments?['age'] is int ? arguments!['age'] : (arguments?['age'] is String ? int.tryParse(arguments!['age'] as String) : null)) ?? 0;
          final String healthStatus = arguments?['healthStatus'] as String? ?? 'Tidak Diketahui';
          final int? patientIdFromArgs = _parsePatientId(arguments?['patientId'], '/home_page'); 
          final resolvedPatientId = patientIdFromArgs ?? currentPatientId;

          if (resolvedPatientId != null && currentPatientId == null) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                updateCurrentPatientId(resolvedPatientId);
             });
          }
          print("Navigating to /home_page with patientId: $resolvedPatientId, userName: $userName, healthStatus: $healthStatus");

          return HomePage(
            userName: userName,
            userAge: userAge,
            healthStatus: healthStatus,
            patientId: resolvedPatientId,
          );
        },
        '/home': (context) { // Rute '/home' yang Anda miliki sebelumnya
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final String userName = arguments?['name'] as String? ?? 'Pengguna';
          // Perbaikan parsing age jika mungkin String
          final int userAge = (arguments?['age'] is int ? arguments!['age'] : (arguments?['age'] is String ? int.tryParse(arguments!['age'] as String) : null)) ?? 0;
          final String healthStatus = arguments?['healthStatus'] as String? ?? 'Tidak Diketahui';
          // Perbaikan: Tambahkan argumen kedua untuk _parsePatientId
          final int? patientIdFromArgs = _parsePatientId(arguments?['patientId'], '/home'); 
          final resolvedPatientId = patientIdFromArgs ?? currentPatientId;

           if (resolvedPatientId != null && currentPatientId == null) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                updateCurrentPatientId(resolvedPatientId);
             });
          }
          print("Navigating to /home with patientId: $resolvedPatientId, userName: $userName, healthStatus: $healthStatus");
          return HomePage(
            userName: userName,
            userAge: userAge,
            healthStatus: healthStatus,
            patientId: resolvedPatientId,
          );
        },
        '/schedule': (context) => const ScheduleScreen(),
        '/health': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? patientIdFromArgs = _parsePatientId(arguments?['patientId'], '/health'); 
          final resolvedPatientId = patientIdFromArgs ?? currentPatientId;
          
          print("Navigating to /health. Args: $arguments, patientIdFromArgs: $patientIdFromArgs, currentPatientId: $currentPatientId, resolvedPatientId: $resolvedPatientId");

          if (resolvedPatientId == null) {
             print("Error: No valid patientId for /health route. Displaying HealthScreen with patientId: -1");
             return const HealthScreen(patientId: -1); 
          }
          return HealthScreen(patientId: resolvedPatientId);
        },
        '/history': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final int? patientIdFromArgs = _parsePatientId(arguments?['patientId'], '/history'); 
          final resolvedPatientId = patientIdFromArgs ?? currentPatientId;

          print("Navigating to /history. Args: $arguments, patientIdFromArgs: $patientIdFromArgs, currentPatientId: $currentPatientId, resolvedPatientId: $resolvedPatientId");

          if (resolvedPatientId == null) {
            print("Error: No valid patientId for /history route. Displaying error screen.");
            return Scaffold(
              appBar: AppBar(title: const Text('Error Riwayat')),
              body: const Center(
                child: Text('ID Pasien tidak ditemukan untuk menampilkan riwayat kontrol.'),
              ),
            );
          }
          return RiwayatKontrolScreen(patientId: resolvedPatientId);
        },
        '/notification': (context) => const NotificationScreen(),
        '/settings': (context) => const SettingsScreen(), 
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error Navigasi')),
            body: Center(
              child: Text('Halaman tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
