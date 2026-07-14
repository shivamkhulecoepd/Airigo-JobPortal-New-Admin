// ============================================================
// models/job_model.dart
// Redesigned to match PHP Backend API structure exactly
// Backend: Job.php - All fields mapped 1:1
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';

enum JobType { fullTime, partTime, contract, internship }

extension JobTypeExtension on JobType {
  String get label {
    switch (this) {
      case JobType.fullTime: return 'Full-time';
      case JobType.partTime: return 'Part-time';
      case JobType.contract: return 'Contract';
      case JobType.internship: return 'Internship';
    }
  }

  Color get color {
    switch (this) {
      case JobType.fullTime: return AppColors.secondary;
      case JobType.partTime: return AppColors.accent;
      case JobType.contract: return AppColors.warning;
      case JobType.internship: return Colors.orange;
    }
  }

  static JobType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'full-time': return JobType.fullTime;
      case 'part-time': return JobType.partTime;
      case 'contract': return JobType.contract;
      case 'internship': return JobType.internship;
      default: return JobType.fullTime;
    }
  }
}

class JobModel {
  // Backend API fields - exact mapping from PHP Job Model
  final int id;
  final int recruiterUserId;
  final String companyName;
  final String? companyLogoUrl;
  final String? companyUrl; // New field from backend
  final String designation;
  final String ctc; // Format: "2-6 LPA" or "10-15 LPA"
  final String location;
  final String category;
  final String? description;
  final List<String>? requirements;
  final List<String>? skillsRequired;
  final List<String>? perksAndBenefits;
  final String? experienceRequired;
  final bool isActive;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final bool isUrgentHiring;
  final String jobType;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Frontend-only computed/display fields
  final bool isInWishlist;
  double? _ctcMin;
  double? _ctcMax;
  int? applicantsCount;
  int? viewsCount;
  int? matchPercentage;
  final List<String> recentApplicantPhotos;

  JobModel({
    required this.id,
    required this.recruiterUserId,
    required this.companyName,
    this.companyLogoUrl,
    this.companyUrl,
    required this.designation,
    required this.ctc,
    required this.location,
    required this.category,
    this.description,
    this.requirements,
    this.skillsRequired,
    this.perksAndBenefits,
    this.experienceRequired,
    this.isActive = true,
    this.approvalStatus = 'pending',
    this.isUrgentHiring = false,
    this.jobType = 'Full-time',
    required this.createdAt,
    required this.updatedAt,
    this.isInWishlist = false,
    this.applicantsCount,
    this.viewsCount,
    this.matchPercentage,
    this.recentApplicantPhotos = const [],
  }) {
    _parseCtcRange();
  }

  void _parseCtcRange() {
    if (ctc.isNotEmpty) {
      final ctcMatch = RegExp(r'(\d+(?:\.\d+)?)[\s-]+(\d+(?:\.\d+)?)').firstMatch(ctc);
      if (ctcMatch != null) {
        _ctcMin = double.parse(ctcMatch.group(1)!);
        _ctcMax = double.parse(ctcMatch.group(2)!);
      }
    }
  }

  // Computed getters
  double? get ctcMin => _ctcMin;
  double? get ctcMax => _ctcMax;
  
  String get ctcRange {
    if (_ctcMin != null && _ctcMax != null) {
      return '₹${_ctcMin!.toStringAsFixed(0)}-${_ctcMax!.toStringAsFixed(0)} LPA';
    }
    return ctc;
  }

  String get experienceDisplay {
    if (experienceRequired != null && experienceRequired!.isNotEmpty) {
      // If it's already in the format like "0-1 year" or "2-5 years", return as is
      if (RegExp(r'^\d+-\d+\s*(year|years)$', caseSensitive: false).hasMatch(experienceRequired!)) {
        return experienceRequired!;
      }
      // Otherwise, add "years" to the numeric value
      return '$experienceRequired years';
    }
    return 'Not specified';
  }

  JobType get jobTypeEnum => JobTypeExtension.fromString(jobType);

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as int? ?? 0,
      recruiterUserId: json['recruiter_user_id'] as int? ?? 0,
      companyName: json['company_name'] as String? ?? 'Unknown',
      companyLogoUrl: json['company_logo_url'] as String?,
      companyUrl: json['company_url'] as String?,
      designation: json['designation'] as String? ?? 'Unknown',
      ctc: json['ctc'] as String? ?? '',
      location: json['location'] as String? ?? 'Not specified',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String?,
      requirements: _parseStringList(json['requirements']),
      skillsRequired: _parseStringList(json['skills_required']),
      perksAndBenefits: _parseStringList(json['perks_and_benefits']),
      experienceRequired: json['experience_required']?.toString(),
      isActive: (json['is_active'] ?? 1) == 1 || (json['is_active'] ?? true) == true,
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      isUrgentHiring: (json['is_urgent_hiring'] ?? 0) == 1 || (json['is_urgent_hiring'] ?? false) == true,
      jobType: json['job_type'] as String? ?? 'Full-time',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : DateTime.now(),
      isInWishlist: json['is_in_wishlist'] as bool? ?? false,
      applicantsCount: json['applicants_count'] as int?,
      viewsCount: json['views_count'] as int?,
      matchPercentage: json['match_percentage'] as int?,
      recentApplicantPhotos: (json['recent_applicant_photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  // Helper method to parse string lists from both List and JSON string formats
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    
    // If it's already a List, convert to List<String>
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    
    // If it's a String, try to parse it as JSON
    if (value is String) {
      try {
        final parsed = jsonDecode(value);
        if (parsed is List) {
          return parsed.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // If parsing fails, return the string as a single-item list
        return value.isNotEmpty ? [value] : null;
      }
    }
    
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recruiter_user_id': recruiterUserId,
    'company_name': companyName,
    'company_logo_url': companyLogoUrl,
    'company_url': companyUrl,
    'designation': designation,
    'ctc': ctc,
    'location': location,
    'category': category,
    'description': description,
    'requirements': requirements,
    'skills_required': skillsRequired,
    'perks_and_benefits': perksAndBenefits,
    'recent_applicant_photos': recentApplicantPhotos,
    'experience_required': experienceRequired,
    'is_active': isActive,
    'approval_status': approvalStatus,
    'is_urgent_hiring': isUrgentHiring,
    'job_type': jobType,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_in_wishlist': isInWishlist,
    'applicants_count': applicantsCount,
    'views_count': viewsCount,
    'match_percentage': matchPercentage,
  };

  JobModel copyWith({
    int? id,
    int? recruiterUserId,
    String? companyName,
    String? companyLogoUrl,
    String? companyUrl,
    String? designation,
    String? ctc,
    String? location,
    String? category,
    String? description,
    List<String>? requirements,
    List<String>? skillsRequired,
    List<String>? perksAndBenefits,
    String? experienceRequired,
    bool? isActive,
    String? approvalStatus,
    bool? isUrgentHiring,
    String? jobType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isInWishlist,
    int? applicantsCount,
    int? viewsCount,
    int? matchPercentage,
    List<String>? recentApplicantPhotos,
  }) {
    return JobModel(
      id: id ?? this.id,
      recruiterUserId: recruiterUserId ?? this.recruiterUserId,
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      companyUrl: companyUrl ?? this.companyUrl,
      designation: designation ?? this.designation,
      ctc: ctc ?? this.ctc,
      location: location ?? this.location,
      category: category ?? this.category,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      perksAndBenefits: perksAndBenefits ?? this.perksAndBenefits,
      experienceRequired: experienceRequired ?? this.experienceRequired,
      isActive: isActive ?? this.isActive,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isUrgentHiring: isUrgentHiring ?? this.isUrgentHiring,
      jobType: jobType ?? this.jobType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isInWishlist: isInWishlist ?? this.isInWishlist,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      recentApplicantPhotos: recentApplicantPhotos ?? this.recentApplicantPhotos,
    );
  }
}
