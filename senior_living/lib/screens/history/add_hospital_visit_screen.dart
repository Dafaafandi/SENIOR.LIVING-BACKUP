import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/hospital_visit.dart';
import '../../services/api_service.dart';

class AddHospitalVisitScreen extends StatefulWidget {
  final int patientId;

  const AddHospitalVisitScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  _AddHospitalVisitScreenState createState() => _AddHospitalVisitScreenState();
}

class _AddHospitalVisitScreenState extends State<AddHospitalVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _doctorNameController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field yang wajib')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newVisit = HospitalVisit(
        id: 0,
        patientId: widget.patientId,
        hospitalName: _hospitalNameController.text,
        doctorName: _doctorNameController.text.isEmpty
            ? null
            : _doctorNameController.text,
        visitDate: _selectedDate!,
        reason: _diagnosisController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _apiService.addHospitalVisit(newVisit);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Riwayat Kontrol'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _hospitalNameController,
                decoration: const InputDecoration(
                    labelText: 'Nama Rumah Sakit/Klinik *'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field ini wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doctorNameController,
                decoration:
                    const InputDecoration(labelText: 'Nama Dokter (Opsional)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Pilih Tanggal Kunjungan *'
                    : 'Tanggal: ${DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: 'Diagnosis *'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Field ini wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Catatan Tambahan'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Simpan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
