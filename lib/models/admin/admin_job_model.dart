import 'package:airigo_jobportal/models/job_model.dart';

class AdminJobModel {
  final int id;
  final int recruiterUserId;
  final String companyName;
  final String? companyUrl;
  final String? companyLogoUrl;
  final String designation;
  final String ctc;
  final String location;
  final String category;
  final String? description;
  final List<String>? requirements;
  final List<String>? skillsRequired;
  final List<String>? perksAndBenefits;
  final String? experienceRequired;
  final bool isActive;
  final String approvalStatus;
  final bool isUrgentHiring;
  final String jobType;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional info
  final String? recruiterEmail;
  final String? recruiterName;
  final int? applicationCount;

  AdminJobModel({
    required this.id,
    required this.recruiterUserId,
    required this.companyName,
    this.companyUrl,
    this.companyLogoUrl,
    required this.designation,
    required this.ctc,
    required this.location,
    required this.category,
    this.description,
    this.requirements,
    this.skillsRequired,
    this.perksAndBenefits,
    this.experienceRequired,
    required this.isActive,
    required this.approvalStatus,
    required this.isUrgentHiring,
    required this.jobType,
    required this.createdAt,
    required this.updatedAt,
    this.recruiterEmail,
    this.recruiterName,
    this.applicationCount,
  });

  factory AdminJobModel.fromJson(Map<String, dynamic> json) {
    // Helper function to handle fields that could be String or List
    List<String>? parseListField(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return List<String>.from(value.map((e) => e.toString()));
      }
      if (value is String) {
        // If it's a string that looks like a JSON array, parse it
        if (value.startsWith('[') && value.endsWith(']')) {
          try {
            // Try to parse as JSON array
            final parsed = <String>[];
            // Remove brackets and split by comma
            final items = value.substring(1, value.length - 1);
            if (items.isNotEmpty) {
              for (var item in items.split(',')) {
                // Remove quotes and trim
                var cleaned = item.trim().replaceAll('"', '').replaceAll("'", '').replaceAll("\\", '').trim();
                if (cleaned.isNotEmpty) {
                  parsed.add(cleaned);
                }
              }
            }
            return parsed.isEmpty ? null : parsed;
          } catch (e) {
            // If parsing fails, return as single item
            return [value];
          }
        }
        // If it's a string, split by comma or return as single item
        if (value.contains(',')) {
          return value.split(',').map((e) => e.trim()).toList();
        }
        return [value];
      }
      return null;
    }
    
    // Helper function to handle bool fields that could be int (0/1) or bool
    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }

    return AdminJobModel(
      id: json['id'] ?? 0,
      recruiterUserId: json['recruiter_user_id'] ?? 0,
      companyName: json['company_name'] ?? '',
      companyUrl: json['company_url'],
      companyLogoUrl: json['company_logo_url'],
      designation: json['designation'] ?? '',
      ctc: json['ctc'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      description: json['description'],
      requirements: parseListField(json['requirements']),
      skillsRequired: parseListField(json['skills_required']),
      perksAndBenefits: parseListField(json['perks_and_benefits']),
      experienceRequired: json['experience_required']?.toString(),
      isActive: parseBool(json['is_active'], defaultValue: true),
      approvalStatus: json['approval_status'] ?? 'pending',
      isUrgentHiring: parseBool(json['is_urgent_hiring']),
      jobType: json['job_type'] ?? 'Full-time',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      recruiterEmail: json['recruiter_email'],
      recruiterName: json['recruiter_name'],
      applicationCount: json['application_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recruiter_user_id': recruiterUserId,
      'company_name': companyName,
      'company_url': companyUrl,
      'company_logo_url': companyLogoUrl,
      'designation': designation,
      'ctc': ctc,
      'location': location,
      'category': category,
      'description': description,
      'requirements': requirements,
      'skills_required': skillsRequired,
      'perks_and_benefits': perksAndBenefits,
      'experience_required': experienceRequired,
      'is_active': isActive,
      'approval_status': approvalStatus,
      'is_urgent_hiring': isUrgentHiring,
      'job_type': jobType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'recruiter_email': recruiterEmail,
      'recruiter_name': recruiterName,
      'application_count': applicationCount,
    };
  }
}
