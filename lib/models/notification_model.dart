// ============================================================
// models/notification_model.dart
// ============================================================

import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  applicationStatus,
  newJobMatch,
  similarJobsAvailable,
  companyHiringAlert,
  jobExpiringSoon,
  profileView,
  profileShortlisted,
  resumeViewed,
  message,
  reminder,
  system,
  newApplication,
  welcome,
  accountVerification,
  accountVerificationPending,
  accountRejected,
  accountSuspended,
  verificationDocumentsRequired,
  passwordReset,
  passwordChanged,
  interviewScheduled,
  offerExtended,
  jobExpiry,
  jobPosted,
  jobApproval,
  jobRejected,
  newUserRegistration,
  newRecruiterRegistration,
  userVerificationRequired,
  suspiciousActivityDetected,
  userReported,
  accountDeletionRequest,
  newJobPosted,
  jobReportFiled,
  applicationReportFiled,
  profileReportFiled,
  fraudulentJobDetected,
  spamContentDetected,
  applicationFollowUp,
  wishlistJobUpdate,
  systemMaintenance,
  platformUpdate,
  policyUpdate,
  newFeatureAnnouncement,
  emergencyBroadcast,
  holidaySchedule,
  candidateResponded,
  highProfileCandidateApplied,
  candidateScheduledInterview,
  candidateMissedInterview,
  subscriptionRenewal,
  paymentSuccessful,
  paymentFailed,
  invoiceReady,
  adminMessage,
  supportResponse,
  featureRequest,
  newSupportTicket,
  escalatedIssue,
  criticalBugReported,
  systemDowntime,
  performanceIssue,
  securityBreach,
  databaseBackupComplete,
  serverResourceAlert,
  dailyActivitySummary,
  weeklyPlatformMetrics,
  monthlyAnalyticsReport,
  revenueReport,
  userGrowthStatistics,
  privacyPolicyViolation,
  termsOfServiceViolation,
  gdprComplianceAlert,
  legalRequestReceived,
}

extension NotificationTypeExtension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.applicationStatus: return Icons.work_rounded;
      case NotificationType.newJobMatch: return Icons.star_rounded;
      case NotificationType.similarJobsAvailable: return Icons.copy_rounded;
      case NotificationType.companyHiringAlert: return Icons.business_rounded;
      case NotificationType.jobExpiringSoon: return Icons.timer_rounded;
      case NotificationType.profileView: return Icons.visibility_rounded;
      case NotificationType.profileShortlisted: return Icons.assignment_turned_in_rounded;
      case NotificationType.resumeViewed: return Icons.description_rounded;
      case NotificationType.message: return Icons.chat_bubble_rounded;
      case NotificationType.reminder: return Icons.alarm_rounded;
      case NotificationType.system: return Icons.info_rounded;
      case NotificationType.newApplication: return Icons.assignment_ind_rounded;
      case NotificationType.welcome: return Icons.celebration_rounded;
      case NotificationType.accountVerification: return Icons.verified_rounded;
      case NotificationType.accountVerificationPending: return Icons.pending_rounded;
      case NotificationType.accountRejected: return Icons.cancel_rounded;
      case NotificationType.accountSuspended: return Icons.block_rounded;
      case NotificationType.verificationDocumentsRequired: return Icons.file_present_rounded;
      case NotificationType.passwordReset: return Icons.lock_reset_rounded;
      case NotificationType.passwordChanged: return Icons.lock_outline_rounded;
      case NotificationType.interviewScheduled: return Icons.event_available_rounded;
      case NotificationType.offerExtended: return Icons.attach_money_rounded;
      case NotificationType.jobExpiry: return Icons.hourglass_empty_rounded;
      case NotificationType.jobPosted: return Icons.check_circle_rounded;
      case NotificationType.jobApproval: return Icons.check_circle_outline_rounded;
      case NotificationType.jobRejected: return Icons.error_outline_rounded;
      case NotificationType.newUserRegistration: return Icons.person_add_rounded;
      case NotificationType.newRecruiterRegistration: return Icons.business_center_rounded;
      case NotificationType.userVerificationRequired: return Icons.verified_user_rounded;
      case NotificationType.suspiciousActivityDetected: return Icons.warning_rounded;
      case NotificationType.userReported: return Icons.flag_rounded;
      case NotificationType.accountDeletionRequest: return Icons.delete_rounded;
      case NotificationType.newJobPosted: return Icons.post_add_rounded;
      case NotificationType.jobReportFiled: return Icons.flag_rounded;
      case NotificationType.applicationReportFiled: return Icons.flag_rounded;
      case NotificationType.profileReportFiled: return Icons.flag_rounded;
      case NotificationType.fraudulentJobDetected: return Icons.block_rounded;
      case NotificationType.spamContentDetected: return Icons.block_rounded;
      case NotificationType.applicationFollowUp: return Icons.follow_the_signs_rounded;
      case NotificationType.wishlistJobUpdate: return Icons.favorite_rounded;
      case NotificationType.systemMaintenance: return Icons.build_rounded;
      case NotificationType.platformUpdate: return Icons.update_rounded;
      case NotificationType.policyUpdate: return Icons.gavel_rounded;
      case NotificationType.newFeatureAnnouncement: return Icons.campaign_rounded;
      case NotificationType.emergencyBroadcast: return Icons.notification_important_rounded;
      case NotificationType.holidaySchedule: return Icons.event_note_rounded;
      case NotificationType.candidateResponded: return Icons.reply_rounded;
      case NotificationType.highProfileCandidateApplied: return Icons.star_border_rounded;
      case NotificationType.candidateScheduledInterview: return Icons.schedule_rounded;
      case NotificationType.candidateMissedInterview: return Icons.cancel_rounded;
      case NotificationType.subscriptionRenewal: return Icons.refresh_rounded;
      case NotificationType.paymentSuccessful: return Icons.payment_rounded;
      case NotificationType.paymentFailed: return Icons.payment_rounded;
      case NotificationType.invoiceReady: return Icons.receipt_rounded;
      case NotificationType.adminMessage: return Icons.admin_panel_settings_rounded;
      case NotificationType.supportResponse: return Icons.headset_rounded;
      case NotificationType.featureRequest: return Icons.lightbulb_rounded;
      case NotificationType.newSupportTicket: return Icons.help_center_rounded;
      case NotificationType.escalatedIssue: return Icons.error_rounded;
      case NotificationType.criticalBugReported: return Icons.bug_report_rounded;
      case NotificationType.systemDowntime: return Icons.warning_rounded;
      case NotificationType.performanceIssue: return Icons.speed_rounded;
      case NotificationType.securityBreach: return Icons.security_rounded;
      case NotificationType.databaseBackupComplete: return Icons.backup_rounded;
      case NotificationType.serverResourceAlert: return Icons.memory_rounded;
      case NotificationType.dailyActivitySummary: return Icons.bar_chart_rounded;
      case NotificationType.weeklyPlatformMetrics: return Icons.trending_up_rounded;
      case NotificationType.monthlyAnalyticsReport: return Icons.analytics_rounded;
      case NotificationType.revenueReport: return Icons.monetization_on_rounded;
      case NotificationType.userGrowthStatistics: return Icons.group_add_rounded;
      case NotificationType.privacyPolicyViolation: return Icons.privacy_tip_rounded;
      case NotificationType.termsOfServiceViolation: return Icons.gavel_rounded;
      case NotificationType.gdprComplianceAlert: return Icons.privacy_tip_rounded;
      case NotificationType.legalRequestReceived: return Icons.gavel_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.applicationStatus: return AppColors.success;
      case NotificationType.newJobMatch: return AppColors.secondary;
      case NotificationType.similarJobsAvailable: return AppColors.primary;
      case NotificationType.companyHiringAlert: return AppColors.accent;
      case NotificationType.jobExpiringSoon: return AppColors.warning;
      case NotificationType.profileView: return AppColors.accent;
      case NotificationType.profileShortlisted: return AppColors.success;
      case NotificationType.resumeViewed: return AppColors.primary;
      case NotificationType.message: return AppColors.primary;
      case NotificationType.reminder: return AppColors.warning;
      case NotificationType.system: return AppColors.textMuted;
      case NotificationType.newApplication: return AppColors.primary;
      case NotificationType.welcome: return AppColors.success;
      case NotificationType.accountVerification: return AppColors.success;
      case NotificationType.accountVerificationPending: return AppColors.warning;
      case NotificationType.accountRejected: return AppColors.error;
      case NotificationType.accountSuspended: return AppColors.error;
      case NotificationType.verificationDocumentsRequired: return AppColors.warning;
      case NotificationType.passwordReset: return AppColors.warning;
      case NotificationType.passwordChanged: return AppColors.success;
      case NotificationType.interviewScheduled: return AppColors.primary;
      case NotificationType.offerExtended: return AppColors.success;
      case NotificationType.jobExpiry: return AppColors.warning;
      case NotificationType.jobPosted: return AppColors.success;
      case NotificationType.jobApproval: return AppColors.success;
      case NotificationType.jobRejected: return AppColors.error;
      case NotificationType.newUserRegistration: return AppColors.primary;
      case NotificationType.newRecruiterRegistration: return AppColors.primary;
      case NotificationType.userVerificationRequired: return AppColors.warning;
      case NotificationType.suspiciousActivityDetected: return AppColors.error;
      case NotificationType.userReported: return AppColors.warning;
      case NotificationType.accountDeletionRequest: return AppColors.warning;
      case NotificationType.newJobPosted: return AppColors.primary;
      case NotificationType.jobReportFiled: return AppColors.warning;
      case NotificationType.applicationReportFiled: return AppColors.warning;
      case NotificationType.profileReportFiled: return AppColors.warning;
      case NotificationType.fraudulentJobDetected: return AppColors.error;
      case NotificationType.spamContentDetected: return AppColors.warning;
      case NotificationType.applicationFollowUp: return AppColors.primary;
      case NotificationType.wishlistJobUpdate: return AppColors.accent;
      case NotificationType.systemMaintenance: return AppColors.warning;
      case NotificationType.platformUpdate: return AppColors.primary;
      case NotificationType.policyUpdate: return AppColors.warning;
      case NotificationType.newFeatureAnnouncement: return AppColors.success;
      case NotificationType.emergencyBroadcast: return AppColors.error;
      case NotificationType.holidaySchedule: return AppColors.primary;
      case NotificationType.candidateResponded: return AppColors.primary;
      case NotificationType.highProfileCandidateApplied: return AppColors.warning;
      case NotificationType.candidateScheduledInterview: return AppColors.primary;
      case NotificationType.candidateMissedInterview: return AppColors.error;
      case NotificationType.subscriptionRenewal: return AppColors.warning;
      case NotificationType.paymentSuccessful: return AppColors.success;
      case NotificationType.paymentFailed: return AppColors.error;
      case NotificationType.invoiceReady: return AppColors.primary;
      case NotificationType.adminMessage: return AppColors.primary;
      case NotificationType.supportResponse: return AppColors.primary;
      case NotificationType.featureRequest: return AppColors.primary;
      case NotificationType.newSupportTicket: return AppColors.primary;
      case NotificationType.escalatedIssue: return AppColors.error;
      case NotificationType.criticalBugReported: return AppColors.error;
      case NotificationType.systemDowntime: return AppColors.error;
      case NotificationType.performanceIssue: return AppColors.warning;
      case NotificationType.securityBreach: return AppColors.error;
      case NotificationType.databaseBackupComplete: return AppColors.success;
      case NotificationType.serverResourceAlert: return AppColors.warning;
      case NotificationType.dailyActivitySummary: return AppColors.primary;
      case NotificationType.weeklyPlatformMetrics: return AppColors.primary;
      case NotificationType.monthlyAnalyticsReport: return AppColors.primary;
      case NotificationType.revenueReport: return AppColors.primary;
      case NotificationType.userGrowthStatistics: return AppColors.primary;
      case NotificationType.privacyPolicyViolation: return AppColors.warning;
      case NotificationType.termsOfServiceViolation: return AppColors.warning;
      case NotificationType.gdprComplianceAlert: return AppColors.warning;
      case NotificationType.legalRequestReceived: return AppColors.warning;
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final bool isArchived;
  final Map<String, dynamic>? data;
  final String? actionRoute;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.isArchived = false,
    this.data,
    this.actionRoute,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    bool? isArchived,
    Map<String, dynamic>? data,
    String? actionRoute,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      data: data ?? this.data,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? 'New notification',
      type: fromTypeString(json['type'] ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      isRead: _safeBooleanCheck(json['is_read']),
      isArchived: _safeBooleanCheck(json['is_archived']),
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      actionRoute: json['action_route'] ?? json['route'],
    );
  }

  static bool _safeBooleanCheck(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static NotificationType fromTypeString(String type) {
    switch (type.toLowerCase()) {
      case 'application_status': return NotificationType.applicationStatus;
      case 'new_job_match': return NotificationType.newJobMatch;
      case 'similar_jobs_available': return NotificationType.similarJobsAvailable;
      case 'company_hiring_alert': return NotificationType.companyHiringAlert;
      case 'job_expiring_soon': return NotificationType.jobExpiringSoon;
      case 'profile_view': return NotificationType.profileView;
      case 'profile_shortlisted': return NotificationType.profileShortlisted;
      case 'resume_viewed': return NotificationType.resumeViewed;
      case 'message': return NotificationType.message;
      case 'new_application': return NotificationType.newApplication;
      case 'welcome': return NotificationType.welcome;
      case 'account_verification': return NotificationType.accountVerification;
      case 'account_verification_pending': return NotificationType.accountVerificationPending;
      case 'account_rejected': return NotificationType.accountRejected;
      case 'account_suspended': return NotificationType.accountSuspended;
      case 'verification_documents_required': return NotificationType.verificationDocumentsRequired;
      case 'password_reset': return NotificationType.passwordReset;
      case 'password_changed': return NotificationType.passwordChanged;
      case 'interview_scheduled': return NotificationType.interviewScheduled;
      case 'offer_extended': return NotificationType.offerExtended;
      case 'job_expiry': return NotificationType.jobExpiry;
      case 'job_posted': return NotificationType.jobPosted;
      case 'job_approved': return NotificationType.jobApproval;
      case 'job_approval': return NotificationType.jobApproval;
      case 'job_rejected': return NotificationType.jobRejected;
      case 'new_user_registration': return NotificationType.newUserRegistration;
      case 'new_recruiter_registration': return NotificationType.newRecruiterRegistration;
      case 'system_maintenance': return NotificationType.systemMaintenance;
      case 'platform_update': return NotificationType.platformUpdate;
      case 'policy_update': return NotificationType.policyUpdate;
      case 'new_feature_announcement': return NotificationType.newFeatureAnnouncement;
      case 'emergency_broadcast': return NotificationType.emergencyBroadcast;
      case 'holiday_schedule': return NotificationType.holidaySchedule;
      case 'candidate_responded': return NotificationType.candidateResponded;
      case 'high_profile_candidate_applied': return NotificationType.highProfileCandidateApplied;
      case 'candidate_scheduled_interview': return NotificationType.candidateScheduledInterview;
      case 'candidate_missed_interview': return NotificationType.candidateMissedInterview;
      case 'subscription_renewal': return NotificationType.subscriptionRenewal;
      case 'payment_successful': return NotificationType.paymentSuccessful;
      case 'payment_failed': return NotificationType.paymentFailed;
      case 'invoice_ready': return NotificationType.invoiceReady;
      case 'admin_message': return NotificationType.adminMessage;
      case 'support_response': return NotificationType.supportResponse;
      case 'feature_request': return NotificationType.featureRequest;
      case 'user_verification_required': return NotificationType.userVerificationRequired;
      case 'suspicious_activity_detected': return NotificationType.suspiciousActivityDetected;
      case 'user_reported': return NotificationType.userReported;
      case 'account_deletion_request': return NotificationType.accountDeletionRequest;
      case 'new_job_posted': return NotificationType.newJobPosted;
      case 'job_report_filed': return NotificationType.jobReportFiled;
      case 'application_report_filed': return NotificationType.applicationReportFiled;
      case 'profile_report_filed': return NotificationType.profileReportFiled;
      case 'fraudulent_job_detected': return NotificationType.fraudulentJobDetected;
      case 'spam_content_detected': return NotificationType.spamContentDetected;
      case 'application_follow_up': return NotificationType.applicationFollowUp;
      case 'wishlist_job_update': return NotificationType.wishlistJobUpdate;
      case 'system_downtime': return NotificationType.systemDowntime;
      case 'performance_issue': return NotificationType.performanceIssue;
      case 'security_breach': return NotificationType.securityBreach;
      case 'database_backup_complete': return NotificationType.databaseBackupComplete;
      case 'server_resource_alert': return NotificationType.serverResourceAlert;
      case 'daily_activity_summary': return NotificationType.dailyActivitySummary;
      case 'weekly_platform_metrics': return NotificationType.weeklyPlatformMetrics;
      case 'monthly_analytics_report': return NotificationType.monthlyAnalyticsReport;
      case 'revenue_report': return NotificationType.revenueReport;
      case 'user_growth_statistics': return NotificationType.userGrowthStatistics;
      case 'new_support_ticket': return NotificationType.newSupportTicket;
      case 'escalated_issue': return NotificationType.escalatedIssue;
      case 'critical_bug_reported': return NotificationType.criticalBugReported;
      case 'privacy_policy_violation': return NotificationType.privacyPolicyViolation;
      case 'terms_of_service_violation': return NotificationType.termsOfServiceViolation;
      case 'gdpr_compliance_alert': return NotificationType.gdprComplianceAlert;
      case 'legal_request_received': return NotificationType.legalRequestReceived;
      default: return NotificationType.system;
    }
  }

  bool get isJobseekerType {
    final types = {
      NotificationType.applicationStatus,
      NotificationType.newJobMatch,
      NotificationType.similarJobsAvailable,
      NotificationType.companyHiringAlert,
      NotificationType.jobExpiringSoon,
      NotificationType.profileView,
      NotificationType.profileShortlisted,
      NotificationType.resumeViewed,
      NotificationType.message,
      NotificationType.interviewScheduled,
      NotificationType.offerExtended,
      NotificationType.jobExpiry,
      NotificationType.welcome,
      NotificationType.accountVerification,
      NotificationType.passwordReset,
      NotificationType.passwordChanged,
      NotificationType.candidateResponded,
      NotificationType.candidateScheduledInterview,
      NotificationType.candidateMissedInterview,
      NotificationType.newJobPosted,
      NotificationType.applicationFollowUp,
      NotificationType.wishlistJobUpdate,
      NotificationType.newFeatureAnnouncement,
      NotificationType.emergencyBroadcast,
      NotificationType.holidaySchedule,
      NotificationType.systemMaintenance,
      NotificationType.platformUpdate,
      NotificationType.policyUpdate,
    };
    return types.contains(type);
  }

  bool get isRecruiterType {
    final types = {
      NotificationType.newApplication,
      NotificationType.candidateResponded,
      NotificationType.interviewScheduled,
      NotificationType.offerExtended,
      NotificationType.candidateScheduledInterview,
      NotificationType.candidateMissedInterview,
      NotificationType.jobApproval,
      NotificationType.jobRejected,
      NotificationType.accountVerification,
      NotificationType.accountVerificationPending,
      NotificationType.accountRejected,
      NotificationType.accountSuspended,
      NotificationType.verificationDocumentsRequired,
      NotificationType.highProfileCandidateApplied,
      NotificationType.newJobPosted,
      NotificationType.jobReportFiled,
      NotificationType.applicationReportFiled,
      NotificationType.fraudulentJobDetected,
      NotificationType.subscriptionRenewal,
      NotificationType.paymentSuccessful,
      NotificationType.paymentFailed,
      NotificationType.invoiceReady,
      NotificationType.jobExpiry,
      NotificationType.newFeatureAnnouncement,
      NotificationType.emergencyBroadcast,
      NotificationType.holidaySchedule,
      NotificationType.systemMaintenance,
      NotificationType.platformUpdate,
      NotificationType.policyUpdate,
    };
    return types.contains(type);
  }

  bool get isAdminType {
    final types = {
      NotificationType.newUserRegistration,
      NotificationType.newRecruiterRegistration,
      NotificationType.userVerificationRequired,
      NotificationType.suspiciousActivityDetected,
      NotificationType.userReported,
      NotificationType.accountDeletionRequest,
      NotificationType.jobReportFiled,
      NotificationType.applicationReportFiled,
      NotificationType.profileReportFiled,
      NotificationType.fraudulentJobDetected,
      NotificationType.spamContentDetected,
      NotificationType.newSupportTicket,
      NotificationType.escalatedIssue,
      NotificationType.criticalBugReported,
      NotificationType.systemDowntime,
      NotificationType.performanceIssue,
      NotificationType.securityBreach,
      NotificationType.databaseBackupComplete,
      NotificationType.serverResourceAlert,
      NotificationType.dailyActivitySummary,
      NotificationType.weeklyPlatformMetrics,
      NotificationType.monthlyAnalyticsReport,
      NotificationType.revenueReport,
      NotificationType.userGrowthStatistics,
      NotificationType.privacyPolicyViolation,
      NotificationType.termsOfServiceViolation,
      NotificationType.gdprComplianceAlert,
      NotificationType.legalRequestReceived,
      // Admin receives these when action is needed:
      NotificationType.newJobPosted,
    };
    return types.contains(type);
  }

  /// Action-required notifications sent directly to admin users
  /// (e.g. new recruiter registration pending approval, new job pending approval).
  bool get isAdminActionType {
    final types = {
      NotificationType.newUserRegistration,
      NotificationType.newRecruiterRegistration,
      NotificationType.newJobPosted,
      NotificationType.userVerificationRequired,
      NotificationType.userReported,
      NotificationType.accountDeletionRequest,
      NotificationType.newSupportTicket,
      NotificationType.escalatedIssue,
    };
    return types.contains(type);
  }

  static List<NotificationModel> get dummyNotifications => [
        NotificationModel(
          id: 'notif_001',
          title: '🎉 Shortlisted at Google India!',
          body: 'Congratulations! Your application for Senior Flutter Developer has been shortlisted. Interview scheduled soon.',
          type: NotificationType.applicationStatus,
          isRead: false,
          actionRoute: '/applications',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: 'notif_002',
          title: '⭐ 5 New Jobs Match Your Profile',
          body: 'We found new Flutter Developer jobs in Pune that are 85%+ match for your skills.',
          type: NotificationType.newJobMatch,
          isRead: false,
          actionRoute: '/search',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        NotificationModel(
          id: 'notif_003',
          title: '👀 Amazon Viewed Your Profile',
          body: 'A recruiter from Amazon India viewed your profile. Keep your profile updated!',
          type: NotificationType.profileView,
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NotificationModel(
          id: 'notif_004',
          title: '📄 Application Update: Swiggy',
          body: 'Your application for UI/UX Designer at Swiggy is under review. You\'ll hear back soon.',
          type: NotificationType.applicationStatus,
          isRead: true,
          actionRoute: '/applications',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        NotificationModel(
          id: 'notif_005',
          title: '🔔 Complete Your Profile',
          body: 'Your profile is 85% complete. Add your education to increase visibility to recruiters.',
          type: NotificationType.reminder,
          isRead: true,
          actionRoute: '/profile/edit',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        NotificationModel(
          id: 'notif_006',
          title: '✅ Offer Accepted: Infosys',
          body: 'Congratulations on your Flutter Intern offer from Infosys! Check your email for details.',
          type: NotificationType.applicationStatus,
          isRead: true,
          actionRoute: '/applications',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
}