// ============================================================
// models/recruiter_model.dart
// ============================================================

class RecruiterModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? company;
  final String? designation;
  final String location;
  final String? idCardUrl;
  final String approvalStatus;
  final int? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final bool isVerified;
  final int profileCompletion;
  final DateTime createdAt;
  final DateTime updatedAt;
  // New fields from backend
  final String? recruiterName;
  final String? companyWebsite;

  const RecruiterModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,

    this.company,
    this.designation,
    this.location = 'Not Mentioned',
    this.idCardUrl,
    this.approvalStatus = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.isVerified = false,
    this.profileCompletion = 60,
    this.recruiterName,
    this.companyWebsite,
  });

  factory RecruiterModel.fromJson(Map<String, dynamic> json) => RecruiterModel(
    id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
    name:
        json['company_name'] ??
        json['name'] ??
        json['email']?.split('@')[0] ??
        'Recruiter',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    avatarUrl: json['photo_url'] ?? json['profile_image_url'],

    company: json['company_name'],
    designation: json['designation'],
    location: json['location'] ?? 'Not Mentioned',
    idCardUrl: json['id_card_url'],
    approvalStatus: json['approval_status'] ?? 'pending',
    approvedBy: json['approved_by'],
    approvedAt: json['approved_at'] != null
        ? DateTime.parse(json['approved_at'])
        : null,
    rejectionReason: json['rejection_reason'],
    isVerified: json['status'] == 'active',
    profileCompletion: 100,
    recruiterName: json['recruiter_name'],
    companyWebsite: json['company_website'],
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'company_name': company,
    'recruiter_name': recruiterName,
    'company_website': companyWebsite,
    'email': email,
    'phone': phone,
    'photo_url': avatarUrl,
    'designation': designation,
    'location': location,
    'id_card_url': idCardUrl,
    'approval_status': approvalStatus,
    'approved_by': approvedBy,
    'approved_at': approvedAt?.toIso8601String(),
    'rejection_reason': rejectionReason,
    'status': isVerified ? 'active' : 'inactive',
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  RecruiterModel copyWith({
    String? name,
    String? company,
    String? designation,
    String? location,
    String? avatarUrl,
    String? idCardUrl,
    String? approvalStatus,
    int? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    bool? isVerified,
    int? profileCompletion,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? recruiterName,
    String? companyWebsite,
  }) {
    return RecruiterModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      company: company ?? this.company,
      designation: designation ?? this.designation,
      location: location ?? this.location,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isVerified: isVerified ?? this.isVerified,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      recruiterName: recruiterName ?? this.recruiterName,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
