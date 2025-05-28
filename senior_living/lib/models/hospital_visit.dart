// lib/models/hospital_visit.dart
import 'package:intl/intl.dart';

class HospitalVisit {
  final int id;
  final int patientId;
  final String hospitalName;
  final String? doctorName;
  final DateTime visitDate;
  final String? reason;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HospitalVisit({
    required this.id,
    required this.patientId,
    required this.hospitalName,
    this.doctorName,
    required this.visitDate,
    this.reason,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory HospitalVisit.fromJson(Map<String, dynamic> json) {
    print("Parsing HospitalVisit from JSON: $json");

    return HospitalVisit(
      id: json['id'] as int,
      patientId: json['patient_id'] as int,
      hospitalName: json['hospital_name'] as String,
      doctorName: json['doctor_name'] as String?,
      visitDate: DateTime.parse(json['visit_date'] as String),
      reason: json['diagnosis'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'hospital_name': hospitalName,
      if (doctorName?.isNotEmpty ?? false) 'doctor_name': doctorName,
      'visit_date': DateFormat('yyyy-MM-dd').format(visitDate),
      if (reason?.isNotEmpty ?? false) 'diagnosis': reason,
      if (notes?.isNotEmpty ?? false) 'notes': notes,
    };
  }
}
