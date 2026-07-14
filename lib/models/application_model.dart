// ============================================================
// models/application_model.dart
// ============================================================

import 'dart:convert';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:flutter/material.dart';

enum ApplicationStatus { pending, shortlisted, accepted, rejected, withdrawn }

extension ApplicationStatusExtension on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.pending: return 'Pending';
      case ApplicationStatus.shortlisted: return 'Shortlisted';
      case ApplicationStatus.accepted: return 'Accepted';
      case ApplicationStatus.rejected: return 'Rejected';
      case ApplicationStatus.withdrawn: return 'Withdrawn';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.pending: return AppColors.statusPending;
      case ApplicationStatus.shortlisted: return AppColors.statusShortlisted;
      case ApplicationStatus.accepted: return AppColors.statusAccepted;
      case ApplicationStatus.rejected: return AppColors.statusRejected;
      case ApplicationStatus.withdrawn: return AppColors.textMuted;
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStatus.pending: return Icons.schedule_rounded;
      case ApplicationStatus.shortlisted: return Icons.star_rounded;
      case ApplicationStatus.accepted: return Icons.check_circle_rounded;
      case ApplicationStatus.rejected: return Icons.cancel_rounded;
      case ApplicationStatus.withdrawn: return Icons.remove_circle_rounded;
    }
  }
}

class ApplicationTimeline {
  final String event;
  final DateTime timestamp;
  final bool isDone;

  const ApplicationTimeline({
    required this.event,
    required this.timestamp,
    required this.isDone,
  });
}

class ApplicationModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String companyLogoUrl;
  final String location;
  final String userId;
  final String resumeUrl;
  final String? coverLetter;
  final ApplicationStatus status;
  final List<ApplicationTimeline> timeline;
  final DateTime appliedAt;
  final DateTime? updatedAt;
  final double ctcMin;
  final double ctcMax;
  final String jobType;
  final String? jobseekerName;
  final String? jobseekerEmail;
  final String? jobseekerPhone;
  final String? jobseekerPhotoUrl;
  final String? jobseekerCurrentRole;
  final List<String>? jobseekerSkills;
  final String? jobseekerBio;
  final String? jobseekerQualification;
  final int? jobseekerExperience;
  // Recruiter fields (from applications for jobseeker)
  final int? recruiterUserId;
  final String? recruiterName;
  final String? recruiterPhotoUrl;
  final String? recruiterDesignation;
  final String? recruiterLocation;
  final String? companyWebsite;
  final String? companyUrl;
  final String? category;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.companyLogoUrl,
    required this.location,
    required this.userId,
    required this.resumeUrl,
    required this.status, required this.timeline, required this.appliedAt, required this.ctcMin, required this.ctcMax, required this.jobType, this.coverLetter,
    this.updatedAt,
    this.jobseekerName,
    this.jobseekerEmail,
    this.jobseekerPhone,
    this.jobseekerPhotoUrl,
    this.jobseekerCurrentRole,
    this.jobseekerSkills,
    this.jobseekerBio,
    this.jobseekerQualification,
    this.jobseekerExperience,
    this.recruiterUserId,
    this.recruiterName,
    this.recruiterPhotoUrl,
    this.recruiterDesignation,
    this.recruiterLocation,
    this.companyWebsite,
    this.companyUrl,
    this.category,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      ApplicationModel(
        id: json['id']?.toString() ?? '',
        jobId: json['job_id']?.toString() ?? '',
        jobTitle: json['designation'] as String? ?? json['job_title'] as String? ?? 'Unknown Position',
        company: json['company_name'] as String? ?? json['company'] as String? ?? 'Unknown Company',
        companyLogoUrl: json['company_logo_url'] as String? ?? '',
        location: json['location'] as String? ?? 'Not specified',
        userId: json['jobseeker_user_id']?.toString() ?? json['user_id']?.toString() ?? '',
        resumeUrl: json['resume_url'] as String? ?? '',
        coverLetter: json['cover_letter'] as String?,
        status: ApplicationStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String? ?? 'pending'),
          orElse: () => ApplicationStatus.pending,
        ),
        timeline: [],
        appliedAt: json['applied_at'] != null 
            ? DateTime.parse(json['applied_at'].toString()) 
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : null,
        ctcMin: _parseCtcMin(json),
        ctcMax: _parseCtcMax(json),
        jobType: json['job_type'] as String? ?? 'Full-time',
        jobseekerName: json['jobseeker_name'] as String? ?? json['name'] as String?,
        jobseekerEmail: json['jobseeker_email'] as String? ?? json['email'] as String?,
        jobseekerPhone: json['jobseeker_phone'] as String? ?? json['phone'] as String?,
        jobseekerPhotoUrl: json['jobseeker_photo_url'] as String? ?? json['photo_url'] as String?,
        jobseekerCurrentRole: json['jobseeker_current_role'] as String? ?? 
                              json['current_role'] as String? ?? 
                              json['jobseeker_bio'] as String? ?? 
                              json['bio'] as String? ??
                              (json['jobseeker_qualification'] != null ? '${json['jobseeker_qualification']} Professional' : null) ??
                              (json['jobseeker_experience'] != null ? 'Professional with ${json['jobseeker_experience']} years experience' : null),
        jobseekerSkills: _parseStringList(json['jobseeker_skills']) ?? _parseStringList(json['skills']),
        jobseekerBio: json['jobseeker_bio'] as String? ?? json['bio'] as String?,
        jobseekerQualification: json['jobseeker_qualification'] as String? ?? json['qualification'] as String?,
        jobseekerExperience: json['jobseeker_experience'] as int?,
        recruiterUserId: json['recruiter_user_id'] as int?,
        recruiterName: json['recruiter_name'] as String?,
        recruiterPhotoUrl: json['recruiter_photo_url'] as String?,
        recruiterDesignation: json['recruiter_designation'] as String?,
        recruiterLocation: json['recruiter_location'] as String?,
        companyWebsite: json['company_website'] as String?,
        companyUrl: json['company_url'] as String?,
        category: json['category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'job_title': jobTitle,
        'company': company,
        'company_logo_url': companyLogoUrl,
        'location': location,
        'user_id': userId,
        'resume_url': resumeUrl,
        'cover_letter': coverLetter,
        'status': status.name,
        'applied_at': appliedAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'ctc_min': ctcMin,
        'ctc_max': ctcMax,
        'job_type': jobType,
        'jobseeker_name': jobseekerName,
        'jobseeker_email': jobseekerEmail,
        'jobseeker_phone': jobseekerPhone,
        'jobseeker_photo_url': jobseekerPhotoUrl,
        'jobseeker_current_role': jobseekerCurrentRole,
        'jobseeker_skills': jobseekerSkills,
        'jobseeker_bio': jobseekerBio,
        'jobseeker_qualification': jobseekerQualification,
        'jobseeker_experience': jobseekerExperience,
        'recruiter_user_id': recruiterUserId,
        'recruiter_name': recruiterName,
        'recruiter_photo_url': recruiterPhotoUrl,
        'recruiter_designation': recruiterDesignation,
        'recruiter_location': recruiterLocation,
        'company_website': companyWebsite,
        'company_url': companyUrl,
        'category': category,
      };

  // Helper methods for parsing CTC values
  static double _parseCtcMin(Map<String, dynamic> json) {
    // Try to parse from ctc field if it's a string like "2-6 LPA"
    if (json['ctc'] is String) {
      final ctc = json['ctc'] as String;
      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(ctc);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
    }
    // Fallback to ctc_min field
    return (json['ctc_min'] as num?)?.toDouble() ?? 0.0;
  }

  static double _parseCtcMax(Map<String, dynamic> json) {
    // Try to parse from ctc field if it's a string like "2-6 LPA"
    if (json['ctc'] is String) {
      final ctc = json['ctc'] as String;
      final matches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(ctc);
      if (matches.length >= 2) {
        return double.parse(matches.elementAt(1).group(1)!);
      } else if (matches.isNotEmpty) {
        return double.parse(matches.first.group(1)!);
      }
    }
    // Fallback to ctc_max field
    return (json['ctc_max'] as num?)?.toDouble() ?? 0.0;
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
}
