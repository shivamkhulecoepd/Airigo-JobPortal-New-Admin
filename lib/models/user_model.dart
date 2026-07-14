// ============================================================
// models/user_model.dart
// ============================================================

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'jobseeker' | 'recruiter'
  final String? avatarUrl;
  final String? bio;
  final List<String> skills;
  final String? qualification;
  final int experienceYears;
  final String? resumeUrl;
  final String? companyName;
  final String? designation;
  final bool isVerified;
  final int profileCompletion;
  final String location;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
    this.role = 'jobseeker',
    this.avatarUrl,
    this.bio,
    this.skills = const [],
    this.qualification,
    this.experienceYears = 0,
    this.resumeUrl,
    this.companyName,
    this.designation,
    this.isVerified = false,
    this.profileCompletion = 60,
    this.location = 'Not Mentioned',
  });

  bool get isRecruiter => role == 'recruiter';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final emailVerified = json['email_verified'];
    final isVerified = emailVerified is int
        ? emailVerified == 1
        : (json['is_verified'] as bool? ?? false);

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['email']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role:
          json['role'] as String? ??
          json['user_type'] as String? ??
          'jobseeker',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      skills: List<String>.from(json['skills'] ?? []),
      qualification: json['qualification'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      resumeUrl: json['resume_url'] as String?,
      companyName: json['company_name'] as String?,
      designation: json['designation'] as String?,
      isVerified: isVerified,
      profileCompletion: json['profile_completion'] as int? ?? 60,
      location: json['location'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar_url': avatarUrl,
    'bio': bio,
    'skills': skills,
    'qualification': qualification,
    'experience_years': experienceYears,
    'resume_url': resumeUrl,
    'company_name': companyName,
    'designation': designation,
    'is_verified': isVerified,
    'profile_completion': profileCompletion,
    'location': location,
    'created_at': createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? name,
    String? bio,
    List<String>? skills,
    String? qualification,
    int? experienceYears,
    String? resumeUrl,
    String? avatarUrl,
    String? location,
    int? profileCompletion,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      qualification: qualification ?? this.qualification,
      experienceYears: experienceYears ?? this.experienceYears,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      companyName: companyName,
      designation: designation,
      isVerified: isVerified,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      location: location ?? this.location,
      createdAt: createdAt,
    );
  }
}
