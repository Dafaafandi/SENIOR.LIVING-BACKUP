// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health/health_record_screen.dart'; // Add this import

//import '../widgets/bottom_nav_bar.dart'; // Jika BottomNavBar adalah widget terpisah
// import '../utils/date_utils.dart'; // Tidak digunakan di sini

class HomePage extends StatefulWidget {
  final String userName;
  final int? userAge; // Bisa jadi null jika tidak ada
  final String healthStatus;
  final int? patientId;

  const HomePage({
    Key? key,
    required this.userName,
    this.userAge,
    required this.healthStatus,
    this.patientId,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late String _currentTime;
  // State lokal tidak lagi mengambil dari ModalRoute.of(context) di didChangeDependencies
  // karena data sudah diteruskan melalui konstruktor widget.

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Data pengguna sudah ada di widget.userName, widget.userAge, widget.healthStatus
    print(
        "HomePage initState: patientId: ${widget.patientId}, userName: ${widget.userName}, healthStatus: ${widget.healthStatus}");
  }

  void _updateTime() {
    _currentTime =
        DateFormat('EEEE, dd MMMM HH:mm', 'id_ID').format(DateTime.now());
    // Panggil setState jika ingin UI diperbarui secara berkala (misalnya, tiap menit)
    // Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTimeDisplay());
  }
  // void _updateTimeDisplay() {
  //   if (mounted) {
  //     setState(() {
  //        _currentTime = DateFormat('EEEE, dd MMMM HH:mm', 'id_ID').format(DateTime.now());
  //     });
  //   }
  // }

  String get _ageText {
    if (widget.userAge != null && widget.userAge! > 0) {
      return "${widget.userAge} Tahun";
    }
    return "Umur tidak diketahui";
  }

  // Metode _performLogout ada di sini
  Future<void> _performLogout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('patient_id');
        await prefs.remove('user_id');

        print("DEBUG: Cleared all session data during logout");

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      } catch (e) {
        print("ERROR: Failed to clear session data: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terjadi kesalahan saat logout')),
          );
        }
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigasi berdasarkan index BottomNavBar
    switch (index) {
      case 0: // Beranda - tidak melakukan apa-apa karena sudah di HomePage
        break;
      case 1: // Jadwal
        Navigator.pushNamed(
          context,
          '/schedule',
          arguments: {
            'patientId': widget.patientId
          }, // Forward patientId if needed
        );
        break;
      case 2: // Kesehatan
        if (widget.patientId != null) {
          Navigator.pushNamed(
            context,
            '/health',
            arguments: {'patientId': widget.patientId}, // patientId sudah int?
          );
        } else {
          _showPatientIdError();
        }
        break;
      case 3: // Pengaturan - Tambahkan jika ada
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  void _showPatientIdError() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('ID Pasien tidak tersedia.'),
      duration: Duration(seconds: 2),
    ));
    print("Error: widget.patientId is null in HomePage.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Halo, Selamat Datang!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // Sesuaikan warna
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentTime,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/notification'),
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.grey, size: 28),
                      ),
                      IconButton(
                        onPressed: _performLogout, // Pemanggilan _performLogout
                        icon: const Icon(Icons.logout,
                            color: Colors.grey, size: 28),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _ageText,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoButton(
                                context: context,
                                label: "Data Kesehatan",
                                icon: Icons.favorite_border,
                                onPressed: () {
                                  if (widget.patientId != null) {
                                    Navigator.pushNamed(context, '/health',
                                        arguments: {
                                          'patientId': widget.patientId
                                        });
                                  } else {
                                    _showPatientIdError();
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildInfoButton(
                                context: context,
                                label: "Jadwal",
                                icon: Icons.calendar_today_outlined,
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/schedule'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.healthStatus.toLowerCase() == "normal" ||
                                widget.healthStatus.toLowerCase() == "baik"
                            ? Colors.green.shade400
                            : (widget.healthStatus.toLowerCase() ==
                                    "tidak diketahui"
                                ? Colors.grey.shade400
                                : Colors.orange.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.healthStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Akses Cepat",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickAccessButton(
                    context,
                    Icons.edit_calendar_outlined,
                    "Tambah Jadwal",
                    () => Navigator.pushNamed(context, '/schedule'),
                  ),
                  _quickAccessButton(
                    context,
                    Icons.medical_services_outlined,
                    "Catat Pemeriksaan",
                    () {
                      if (widget.patientId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HealthRecordScreen(
                                patientId: widget.patientId!),
                          ),
                        );
                      } else {
                        _showPatientIdError();
                      }
                    },
                  ),
                  _quickAccessButton(
                    context,
                    Icons.history_edu_outlined,
                    "Riwayat Kontrol",
                    () {
                      if (widget.patientId != null) {
                        Navigator.pushNamed(context, '/history',
                            arguments: {'patientId': widget.patientId});
                      } else {
                        _showPatientIdError();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              activeIcon: Icon(Icons.favorite),
              label: 'Jadwal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outlined),
              activeIcon: Icon(Icons.favorite),
              label: 'Kesehatan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _quickAccessButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
