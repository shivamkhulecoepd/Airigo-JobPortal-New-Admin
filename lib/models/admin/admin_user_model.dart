import 'package:airigo_jobportal/models/user_model.dart';

class AdminUserModel {
  final int id;
  final String email;
  final String userType;
  final String? phone;
  final String status;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Extended fields for jobseekers
  final String? name;
  final String? location;
  final int? experience;
  final List<String>? skills;
  final String? profileImageUrl;
  final String? qualification;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? resumeUrl;
  final String? resumeFilename;

  // Extended fields for recruiters
  final String? companyName;
  final String? recruiterName;
  final String? approvalStatus;
  final String? designation;
  final String? idCardUrl;
  final String? companyWebsite;
  final String? rejectedReason;

  AdminUserModel({
    required this.id,
    required this.email,
    required this.userType,
    this.phone,
    required this.status,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.location,
    this.experience,
    this.skills,
    this.profileImageUrl,
    this.qualification,
    this.dateOfBirth,
    this.bio,
    this.resumeUrl,
    this.resumeFilename,
    this.companyName,
    this.recruiterName,
    this.approvalStatus,
    this.designation,
    this.idCardUrl,
    this.companyWebsite,
    this.rejectedReason,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    // Helper function to handle skills that could be String or List
    List<String>? parseSkills(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return List<String>.from(value.map((e) => e.toString()));
      }
      if (value is String) {
        if (value.isEmpty) return null;
        // If it's a string, split by comma or return as single item
        if (value.contains(',')) {
          return value.split(',').map((e) => e.trim()).toList();
        }
        return [value];
      }
      return null;
    }

    // Helper to parse bool from int or bool
    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return defaultValue;
    }

    return AdminUserModel(
      id: json['id'] ?? json['user_id'] ?? 0, // Handle both 'id' and 'user_id'
      email: json['email'] ?? '',
      userType: json['user_type'] ?? '',
      phone: json['phone'],
      status: json['status'] ?? 'active',
      emailVerified: parseBool(json['email_verified']),
      createdAt:
          DateTime.tryParse(
            json['created_at'] ?? json['user_created_at'] ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      name: json['name'],
      location: json['location'],
      experience: json['experience'],
      skills: parseSkills(json['skills']),
      // Recruiters: Use photo_url from database (not profile_image_url)
      profileImageUrl: json['profile_image_url'] ?? json['photo_url'],
      qualification: json['qualification'],
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] ?? ''),
      bio: json['bio'],
      resumeUrl: json['resume_url'],
      resumeFilename: json['resume_filename'],
      companyName: json['company_name'],
      recruiterName: json['recruiter_name'],
      approvalStatus: json['approval_status'],
      designation: json['designation'],
      idCardUrl: json['id_card_url'],
      companyWebsite: json['company_website'],
      rejectedReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_type': userType,
      'phone': phone,
      'status': status,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'name': name,
      'location': location,
      'experience': experience,
      'skills': skills,
      'profile_image_url': profileImageUrl,
      'qualification': qualification,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'bio': bio,
      'resume_url': resumeUrl,
      'resume_filename': resumeFilename,
      'company_name': companyName,
      'recruiter_name': recruiterName,
      'approval_status': approvalStatus,
      'designation': designation,
      'id_card_url': idCardUrl,
      'company_website': companyWebsite,
      'rejection_reason': rejectedReason,
    };
  }
}
