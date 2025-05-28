// lib/screens/health/health_record_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/health_record.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class HealthRecordScreen extends StatefulWidget {
  final int patientId;
  final HealthRecord? recordToEdit;
  final ApiService apiService;

  const HealthRecordScreen({
    super.key,
    required this.patientId,
    this.recordToEdit,
    ApiService? apiService,
  }) : apiService = apiService ?? const ApiService(); // Add const here

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isEditMode = false;
  DateTime _selectedDate = DateTime.now();

  // Form controllers
  final TextEditingController bpController = TextEditingController();
  final TextEditingController spo2Controller = TextEditingController();
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController cholesterolController = TextEditingController();
  final TextEditingController uricAcidController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Existing variables
  late final Box<HealthRecord> healthRecordBox;
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    healthRecordBox = Hive.box<HealthRecord>(healthRecordsBoxName);
    _loadHealthRecords();
  }

  Future<void> _loadHealthRecords() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final fetchedRecordsFromServer = await _apiService.getCatatanKesehatan(
        patientId: widget.patientId,
      );

      if (fetchedRecordsFromServer != null) {
        final Map<String, HealthRecord> serverRecordsMap = {
          for (var record in fetchedRecordsFromServer) record.id: record
        };
        final List<String> localKeys =
            healthRecordBox.keys.cast<String>().toList();

        // Sync local with server
        for (String localKey in localKeys) {
          if (!serverRecordsMap.containsKey(localKey)) {
            await healthRecordBox.delete(localKey);
          }
        }

        for (var record in fetchedRecordsFromServer) {
          await healthRecordBox.put(record.id, record);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disinkronkan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<DateTime?> _showDatePickerInDialog(
      BuildContext dialogContext, DateTime initialDate) async {
    return await showDatePicker(
      context: dialogContext,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Kesehatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHealthRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Box<HealthRecord>>(
              valueListenable: healthRecordBox.listenable(),
              builder: (context, box, _) {
                // Ambil data, urutkan dari terbaru ke terlama
                var records = box.values.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Pencatatan Kesehatan",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add,
                                size: 18, color: Colors.white),
                            label: const Text(
                              'Tambah',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _showAddRecordDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: records.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada catatan kesehatan.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 0, 16.0, 16.0),
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                return _buildHealthRecordCard(
                                    records[index], primaryColor);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHealthRecordCard(HealthRecord record, Color primaryColor) {
    final Color cardBackgroundColor = Colors.white;
    final Color orangeButton = Colors.orange.shade600;
    final Color detailButtonColor = Colors.blue.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      color: cardBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateFormat.format(record.date), // Format tanggal
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildReadingRow("Tekanan Darah:", record.bloodPressure ?? '-',
                record.getBloodPressureStatus()),
            const SizedBox(height: 8),
            _buildReadingRow(
                "SpO2:",
                record.spo2 != null ? "${record.spo2}%" : '-',
                record.getSpo2Status()),
            const SizedBox(height: 8),
            _buildReadingRow(
                "Gula Darah:",
                record.bloodSugar != null ? "${record.bloodSugar} mg/dL" : '-',
                record.getBloodSugarStatus()),
            const SizedBox(height: 8),
            _buildReadingRow(
                "Kolesterol:",
                record.cholesterol != null
                    ? "${record.cholesterol} mg/dL"
                    : '-',
                record.getCholesterolStatus()),
            _buildReadingRow(
                "Asam Urat:",
                record.uricAcid != null
                    ? "${record.uricAcid!.toStringAsFixed(1)} mg/dL"
                    : '-',
                record.getUricAcidStatus()),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Catatan: ${record.notes!}",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  label: 'Lihat Grafik',
                  icon: Icons.show_chart, // Atau Icons.timeline
                  color: orangeButton,
                  onPressed: () {
                    // TODO: Implementasi navigasi/tampilkan grafik
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Fitur Grafik belum tersedia')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: 'Detail',
                  icon: Icons.info_outline,
                  color: detailButtonColor,
                  onPressed: () {
                    // TODO: Implementasi navigasi/tampilkan detail
                    _showRecordDetailDialog(
                        record); // Tampilkan detail dalam dialog
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: 'Hapus',
                  icon: Icons.delete_outline,
                  color: Colors.red.shade500,
                  onPressed: () => _deleteRecord(record.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingRow(String label, String value, String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'normal':
      case 'optimal':
        statusColor = Colors.green.shade600;
        break;
      case 'waspada':
      case 'normal tinggi':
        statusColor = Colors.orange.shade700;
        break;
      case 'hipertensi':
      case 'tinggi':
      case 'rendah': // Mungkin rendah juga perlu waspada
        statusColor = Colors.red.shade600;
        break;
      default:
        statusColor = Colors.grey.shade600;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          // Agar teks tidak overflow jika panjang
          child: Text(
            "$label $value",
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
        if (status != '-') // Hanya tampilkan jika ada status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
      ],
    );
  }

  // Fungsi untuk menampilkan dialog tambah data
  Future<void> _showAddRecordDialog({HealthRecord? recordToEdit}) async {
    final formKey = GlobalKey<FormState>();
    final bool isEditMode = recordToEdit != null;

    final dateController = TextEditingController(
        text: recordToEdit != null
            ? _dateFormat.format(recordToEdit.date)
            : _dateFormat.format(DateTime.now()));
    final bpController =
        TextEditingController(text: recordToEdit?.bloodPressure);
    final spo2Controller =
        TextEditingController(text: recordToEdit?.spo2?.toString());
    final sugarController =
        TextEditingController(text: recordToEdit?.bloodSugar?.toString());

    // New controllers for cholesterol and uric acid
    final cholesterolController =
        TextEditingController(text: recordToEdit?.cholesterol?.toString());
    final uricAcidController = TextEditingController(
        text: recordToEdit?.uricAcid?.toString()?.replaceAll('.', ','));

    final notesController = TextEditingController(text: recordToEdit?.notes);
    DateTime selectedDate = recordToEdit?.date ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          bool _isDialogSubmitting = false;

          Future<void> _handleFormSubmit() async {
            if (!formKey.currentState!.validate()) return;

            setDialogState(() => _isDialogSubmitting = true);
            try {
              // Format numeric values properly
              final bloodPressure = bpController.text.trim();
              final spo2Value = spo2Controller.text.isNotEmpty
                  ? int.tryParse(spo2Controller.text.trim())
                  : null;
              final bloodSugarValue = sugarController.text.isNotEmpty
                  ? int.tryParse(sugarController.text.trim())
                  : null;
              final cholesterolValue = cholesterolController.text.isNotEmpty
                  ? int.tryParse(cholesterolController.text.trim())
                  : null;
              final uricAcidValue = uricAcidController.text.isNotEmpty
                  ? double.tryParse(
                      uricAcidController.text.trim().replaceAll(',', '.'))
                  : null;

              Map<String, dynamic> result;

              if (isEditMode) {
                result = await widget.apiService.updateCatatanKesehatan(
                  recordId: recordToEdit!.id,
                  patientId: widget.patientId,
                  tanggalPemeriksaan: selectedDate,
                  tekananDarah: bloodPressure,
                  spo2: spo2Value?.toString(),
                  gulaDarah: bloodSugarValue?.toString(),
                  kolesterol: cholesterolValue?.toString(),
                  asamUrat: uricAcidValue?.toString(),
                  catatan: notesController.text.trim(),
                );
              } else {
                result = await widget.apiService.simpanCatatanKesehatan(
                  patientId: widget.patientId,
                  tanggalPemeriksaan: selectedDate,
                  tekananDarah: bloodPressure,
                  spo2: spo2Value?.toString(),
                  gulaDarah: bloodSugarValue?.toString(),
                  kolesterol: cholesterolValue?.toString(),
                  asamUrat: uricAcidValue?.toString(),
                  catatan: notesController.text.trim(),
                );
              }

              if (result['success']) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                  Navigator.pop(context, true);
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              if (mounted) {
                setDialogState(() => _isDialogSubmitting = false);
              }
            }
          }

          return AlertDialog(
            title: Text(isEditMode
                ? 'Edit Catatan Kesehatan'
                : 'Tambah Catatan Kesehatan'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await _showDatePickerInDialog(
                            context, selectedDate);
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() {
                            selectedDate = picked;
                            dateController.text =
                                _dateFormat.format(selectedDate);
                          });
                        }
                      },
                      validator: (value) => value?.isEmpty == true
                          ? 'Tanggal tidak boleh kosong'
                          : null,
                    ),
                    TextFormField(
                      controller: bpController,
                      decoration: const InputDecoration(
                        labelText: 'Tekanan Darah (cth: 120/80)',
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value?.isNotEmpty == true &&
                            !RegExp(r'^\d{2,3}/\d{2,3}$').hasMatch(value!)) {
                          return 'Format harus berupa angka/angka (mis: 120/80)';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: spo2Controller,
                      decoration: const InputDecoration(labelText: 'SpO2 (%)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isNotEmpty == true) {
                          final intValue = int.tryParse(value!);
                          if (intValue == null ||
                              intValue < 1 ||
                              intValue > 100) {
                            return 'SpO2 harus berupa angka 1-100';
                          }
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: sugarController,
                      decoration: const InputDecoration(
                          labelText: 'Gula Darah (mg/dL)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: cholesterolController,
                      decoration: const InputDecoration(
                          labelText: 'Kolesterol (mg/dL)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: uricAcidController,
                      decoration: const InputDecoration(
                          labelText: 'Asam Urat (mg/dL)',
                          hintText: 'Contoh: 6.2 atau 6,2'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)'),
                      maxLines: null,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Batal'),
                onPressed:
                    _isDialogSubmitting ? null : () => Navigator.of(ctx).pop(),
              ),
              ElevatedButton(
                onPressed: _isDialogSubmitting ? null : _handleFormSubmit,
                child: _isDialogSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Fungsi helper untuk tombol aksi di card
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 14), // Ukuran ikon lebih kecil
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6), // Padding disesuaikan
        textStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500), // Font lebih kecil
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        minimumSize: const Size(0, 30), // Tinggi minimum tombol
      ),
    );
  }

  // Fungsi untuk menghapus record
  Future<void> _deleteRecord(String id) async {
    final record = healthRecordBox.get(id);
    if (record == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
            'Anda yakin ingin menghapus catatan kesehatan tanggal ${_dateFormat.format(record.date)}?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final apiResult = await _apiService.deleteCatatanKesehatan(id);

        if (apiResult['success'] == true) {
          await healthRecordBox.delete(id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(apiResult['message'] ?? 'Catatan berhasil dihapus')),
          );
          await _loadHealthRecords();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(apiResult['message'] ?? 'Gagal menghapus catatan')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Fungsi untuk menampilkan detail record dalam dialog
  Future<void> _showRecordDetailDialog(HealthRecord record) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detail Catatan - ${_dateFormat.format(record.date)}'),
        content: SingleChildScrollView(
          child: ListBody(
            // Menggunakan ListBody agar rapi
            children: <Widget>[
              _detailItem('Tekanan Darah:',
                  '${record.bloodPressure ?? '-'} (${record.getBloodPressureStatus()})'),
              _detailItem(
                  'SpO2:',
                  record.spo2 != null
                      ? '${record.spo2}% (${record.getSpo2Status()})'
                      : '-'),
              _detailItem(
                  'Gula Darah:',
                  record.bloodSugar != null
                      ? '${record.bloodSugar} mg/dL (${record.getBloodSugarStatus()})'
                      : '-'),
              if (record.notes != null && record.notes!.isNotEmpty)
                _detailItem('Catatan:', record.notes!),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Tutup dialog detail dulu
              _showAddRecordDialog(recordToEdit: record); // Buka dialog edit
            },
          ),
          TextButton(
            child: const Text('Tutup'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  // Helper widget untuk item detail di dialog
  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context)
              .style
              .copyWith(fontSize: 14), // Style default teks
          children: <TextSpan>[
            TextSpan(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }

  Future<void> _submitHealthRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Format numeric values properly
      final bloodPressure = bpController.text.trim();
      final spo2Value = spo2Controller.text.isNotEmpty
          ? int.tryParse(spo2Controller.text.trim())
          : null;
      final bloodSugarValue = sugarController.text.isNotEmpty
          ? int.tryParse(sugarController.text.trim())
          : null;
      final cholesterolValue = cholesterolController.text.isNotEmpty
          ? int.tryParse(cholesterolController.text.trim())
          : null;
      final uricAcidValue = uricAcidController.text.isNotEmpty
          ? double.tryParse(uricAcidController.text.trim().replaceAll(',', '.'))
          : null;

      Map<String, dynamic> result;

      if (_isEditMode) {
        result = await widget.apiService.updateCatatanKesehatan(
          recordId: widget.recordToEdit!.id,
          patientId: widget.patientId,
          tanggalPemeriksaan: _selectedDate,
          tekananDarah: bloodPressure,
          spo2: spo2Value?.toString(),
          gulaDarah: bloodSugarValue?.toString(),
          kolesterol: cholesterolValue?.toString(),
          asamUrat: uricAcidValue?.toString(),
          catatan: notesController.text.trim(),
        );
      } else {
        result = await widget.apiService.simpanCatatanKesehatan(
          patientId: widget.patientId,
          tanggalPemeriksaan: _selectedDate,
          tekananDarah: bloodPressure,
          spo2: spo2Value?.toString(),
          gulaDarah: bloodSugarValue?.toString(),
          kolesterol: cholesterolValue?.toString(),
          asamUrat: uricAcidValue?.toString(),
          catatan: notesController.text.trim(),
        );
      }

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    bpController.dispose();
    spo2Controller.dispose();
    sugarController.dispose();
    cholesterolController.dispose();
    uricAcidController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
