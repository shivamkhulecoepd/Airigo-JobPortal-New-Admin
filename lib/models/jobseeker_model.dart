// ============================================================
// models/jobseeker_model.dart
// ============================================================

class JobseekerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? bio;
  final List<String> skills;
  final String? qualification;
  final int experienceYears;
  final String? resumeUrl;
  final String? resumeFilename;
  final String location;
  final String? dateOfBirth;
  final bool isVerified;
  final int profileCompletion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobseekerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt, required this.updatedAt, this.avatarUrl,
    this.bio,
    this.skills = const [],
    this.qualification,
    this.experienceYears = 0,
    this.resumeUrl,
    this.resumeFilename,
    this.location = 'Not Mentioned',
    this.dateOfBirth,
    this.isVerified = false,
    this.profileCompletion = 60,
  });

  factory JobseekerModel.fromJson(Map<String, dynamic> json) => JobseekerModel(
        id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name'] ?? json['email']?.split('@')[0] ?? 'Job Seeker',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        avatarUrl: json['profile_image_url'],
        bio: json['bio'],
        skills: List<String>.from(json['skills'] ?? []),
        qualification: json['qualification'],
        experienceYears: json['experience'] ?? 0,
        resumeUrl: json['resume_url'],
        resumeFilename: json['resume_filename'],
        location: json['location'] ?? 'Not Mentioned',
        dateOfBirth: json['date_of_birth'],
        isVerified: json['status'] == 'active',
        profileCompletion: 100,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profile_image_url': avatarUrl,
        'bio': bio,
        'skills': skills,
        'qualification': qualification,
        'experience': experienceYears,
        'resume_url': resumeUrl,
        'resume_filename': resumeFilename,
        'location': location,
        'date_of_birth': dateOfBirth,
        'status': isVerified ? 'active' : 'inactive',
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  JobseekerModel copyWith({
    String? name,
    String? bio,
    List<String>? skills,
    String? qualification,
    int? experienceYears,
    String? resumeUrl,
    String? avatarUrl,
    String? location,
    int? profileCompletion,
    String? phone,
    String? email,
    String? resumeFilename,
    String? dateOfBirth,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobseekerModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      qualification: qualification ?? this.qualification,
      experienceYears: experienceYears ?? this.experienceYears,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      resumeFilename: resumeFilename ?? this.resumeFilename,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isVerified: isVerified ?? this.isVerified,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}