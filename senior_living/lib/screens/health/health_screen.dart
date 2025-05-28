import 'package:flutter/material.dart';
import 'health_record_screen.dart';

class HealthScreen extends StatelessWidget {
  final int patientId; // Tambahkan parameter ini

  const HealthScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesehatan'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Halaman Kesehatan untuk Patient ID: $patientId'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (patientId != -1) {
                  Navigator.pushNamed(
                    context,
                    '/history',
                    arguments: {'patientId': patientId},
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'ID Pasien tidak valid untuk melihat riwayat.')),
                  );
                  print(
                      "Error: Invalid patientId (-1) in HealthScreen, cannot navigate to history.");
                }
              },
              child: const Text('Lihat Riwayat Kontrol'),
            ),
            // Tambahkan widget lain untuk halaman kesehatan di sini
          ],
        ),
      ),
    );
  }
}
