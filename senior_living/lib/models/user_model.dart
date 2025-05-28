// lib/models/user_model.dart

// Kelas Patient untuk data pasien yang ter-nesting
class Patient {
  final int id;
  final String name;
  final String? birthDate; // Format dari API: "YYYY-MM-DDTHH:mm:ss.000000Z"
  final String? gender;
  final String? address;
  final String? medicalHistory;
  final String? photo;
  final int userId;

  Patient({
    required this.id,
    required this.name,
    this.birthDate,
    this.gender,
    this.address,
    this.medicalHistory,
    this.photo,
    required this.userId,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      name: json['name'] as String,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      medicalHistory: json['medical_history'] as String?,
      photo: json['photo'] as String?,
      userId: json['user_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      'address': address,
      'medical_history': medicalHistory,
      'photo': photo,
      'user_id': userId,
    };
  }
}

// Kelas UserModel sebagai representasi utama data pengguna dari API
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? birthDate; // birth_date di level user dari API
  final int? age; // age di level user dari API
  final int? patientId; // patient_id di level user dari API
  final Patient? patient; // Objek Patient yang ter-nesting
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.birthDate,
    this.age,
    this.patientId,
    this.patient,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      birthDate: json['birth_date'] as String?,
      age: json['age'] as int?,
      patientId: json['patient_id'] as int?,
      patient: json['patient'] != null
          ? Patient.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'birth_date': birthDate,
      'age': age,
      'patient_id': patientId,
      'patient': patient?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
