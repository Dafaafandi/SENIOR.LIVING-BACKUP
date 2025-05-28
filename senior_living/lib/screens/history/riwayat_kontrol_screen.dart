// lib/screens/history/riwayat_kontrol_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/hospital_visit.dart';
import '../../services/api_service.dart';
import 'add_hospital_visit_screen.dart'; // Impor halaman tambah

class RiwayatKontrolScreen extends StatefulWidget {
  final int patientId;

  const RiwayatKontrolScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  _RiwayatKontrolScreenState createState() => _RiwayatKontrolScreenState();
}

class _RiwayatKontrolScreenState extends State<RiwayatKontrolScreen> {
  late Future<List<HospitalVisit>> _hospitalVisitsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadHospitalVisits();
  }

  void _loadHospitalVisits() {
    setState(() {
      // Tambahkan penanganan error pada future itu sendiri untuk logging yang lebih baik
      _hospitalVisitsFuture = _apiService.getHospitalVisits(widget.patientId)
        .catchError((e, stackTrace) {
          print("Error caught in _loadHospitalVisits for patientId ${widget.patientId}: $e");
          print("Stack trace: $stackTrace");
          // Melempar kembali error agar FutureBuilder bisa menanganinya juga
          // atau return list kosong jika ingin menampilkan pesan 'tidak ada data' daripada error
          throw e; 
        });
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date); // Format tanggal Indonesia
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kontrol'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<HospitalVisit>>(
        future: _hospitalVisitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Error in RiwayatKontrolScreen FutureBuilder: ${snapshot.error}");
            // print("Stack trace: ${snapshot.stackTrace}"); // Stacktrace bisa sangat panjang
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            print("RiwayatKontrolScreen: Snapshot has no data (snapshot.hasData is false).");
            return const Center(child: Text('Tidak ada data riwayat kontrol saat ini.'));
          } else if (snapshot.data!.isEmpty) {
            print("RiwayatKontrolScreen: Snapshot data is empty (list is empty).");
            return const Center(child: Text('Belum ada riwayat kontrol yang tercatat.'));
          }

          final visits = snapshot.data!;
          print("RiwayatKontrolScreen: FutureBuilder has data, displaying ${visits.length} visits.");
          if (visits.isNotEmpty) {
            print(
                "RiwayatKontrolScreen: First visit to display: ID ${visits.first.id}, Hospital: ${visits.first.hospitalName}");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              
              // --- UNTUK DEBUGGING TAMPILAN ---
              // Coba kembalikan ListTile sederhana dulu:
              // return ListTile(
              //   leading: Icon(Icons.local_hospital, color: Colors.teal),
              //   title: Text(visit.hospitalName ?? "Nama RS Tidak Ada", style: TextStyle(color: Colors.black)),
              //   subtitle: Text(
              //     "Dokter: ${visit.doctorName ?? "N/A"}\nDiagnosis: ${visit.reason ?? "N/A"}",
              //     style: TextStyle(color: Colors.black54)
              //   ),
              //   isThreeLine: true,
              // );
              // --- AKHIR DEBUGGING TAMPILAN ---

              // Jika ListTile di atas muncul, kembalikan ke Card asli:
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_hospital,
                          color: Colors.teal.shade700, size: 40),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visit.hospitalName, // Pastikan tidak null jika modelnya String non-nullable
                              style: const TextStyle(
                                fontSize: 17, // Sedikit lebih kecil agar pas
                                fontWeight: FontWeight.bold,
                                color: Colors.black87, 
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              _formatDate(visit.visitDate),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6.0),
                            if (visit.doctorName != null &&
                                visit.doctorName!.isNotEmpty)
                              Text(
                                'Dokter: ${visit.doctorName}',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                              ),
                            const SizedBox(height: 4.0),
                            // Menggunakan visit.reason (yang sudah di-map dari diagnosis)
                            if (visit.reason != null &&
                                visit.reason!.isNotEmpty)
                              Text(
                                'Diagnosis: ${visit.reason}', // Label diubah ke Diagnosis
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                              ),
                            if (visit.notes != null && visit.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Catatan: ${visit.notes}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHospitalVisitScreen(patientId: widget.patientId),
            ),
          );
          if (result == true && mounted) { 
            _loadHospitalVisits(); // Muat ulang daftar riwayat jika ada penambahan
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Riwayat Kontrol',
      ),
    );
  }
}
