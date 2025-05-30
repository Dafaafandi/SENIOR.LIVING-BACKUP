import 'package:flutter/material.dart';
import 'health_record_screen.dart';

class HealthScreen extends StatelessWidget {
  final int patientId;

  const HealthScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesehatan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Menu Kesehatan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildMenuCard(
            context: context,
            title: 'Catatan Kesehatan',
            description: 'Catat dan lihat riwayat pemeriksaan kesehatan Anda',
            icon: Icons.favorite_border,
            color: primaryColor,
            onTap: () {
              if (patientId != -1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HealthRecordScreen(patientId: patientId),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            context: context,
            title: 'Riwayat Kontrol',
            description: 'Lihat riwayat kunjungan ke dokter atau rumah sakit',
            icon: Icons.local_hospital_outlined,
            color: Colors.teal,
            onTap: () {
              if (patientId != -1) {
                Navigator.pushNamed(
                  context,
                  '/history',
                  arguments: {'patientId': patientId},
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
