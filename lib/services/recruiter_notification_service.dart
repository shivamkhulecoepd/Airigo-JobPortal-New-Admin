import 'package:airigo_jobportal/services/api/notification_service.dart';
import 'package:airigo_jobportal/core/service_locator.dart';
import 'package:airigo_jobportal/models/notification_model.dart';

class RecruiterNotificationService {
  final NotificationService _notificationService = getIt<NotificationService>();

  // Handle new application notification
  Future<bool> handleNewApplication({
    required String jobId,
    required String candidateName,
    required String candidateEmail,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'New Application Received',
        body: '$candidateName has applied for your job posting.',
        type: 'new_application',
        data: {
          'job_id': jobId,
          'candidate_name': candidateName,
          'candidate_email': candidateEmail,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling new application notification: $e');
      return false;
    }
  }

  // Handle candidate responded notification
  Future<bool> handleCandidateResponded({
    required String jobId,
    required String candidateName,
    required String message,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Candidate Responded',
        body: '$candidateName responded to your message.',
        type: 'candidate_responded',
        data: {
          'job_id': jobId,
          'candidate_name': candidateName,
          'message': message,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling candidate response notification: $e');
      return false;
    }
  }

  // Handle interview scheduled notification
  Future<bool> handleInterviewScheduled({
    required String jobId,
    required String candidateName,
    required String interviewDate,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Interview Scheduled',
        body: 'Interview scheduled with $candidateName for $interviewDate.',
        type: 'interview_scheduled',
        data: {
          'job_id': jobId,
          'candidate_name': candidateName,
          'interview_date': interviewDate,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling interview scheduled notification: $e');
      return false;
    }
  }

  // Handle offer extended notification
  Future<bool> handleOfferExtended({
    required String jobId,
    required String candidateName,
    required String offerDetails,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Offer Extended',
        body: 'Job offer extended to $candidateName.',
        type: 'offer_extended',
        data: {
          'job_id': jobId,
          'candidate_name': candidateName,
          'offer_details': offerDetails,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling offer extended notification: $e');
      return false;
    }
  }

  // Handle high-profile candidate applied notification
  Future<bool> handleHighProfileCandidateApplied({
    required String jobId,
    required String candidateName,
    required String candidateProfile,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'High-Profile Candidate Applied',
        body: '$candidateName, a high-profile candidate, applied for your position.',
        type: 'high_profile_candidate_applied',
        data: {
          'job_id': jobId,
          'candidate_name': candidateName,
          'candidate_profile': candidateProfile,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling high-profile candidate notification: $e');
      return false;
    }
  }

  // Handle candidate missed interview notification
  Future<bool> handleCandidateMissedInterview({
    required String jobId,
    required String candidateName,
    required String interviewDate,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Candidate Missed Interview',
        body: '$candidateName missed the scheduled interview on $interviewDate.',
        type: 'candidate_missed_interview',
        data: {
          'job_id': jobId,
          'candidate_name': candidateName,
          'interview_date': interviewDate,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling candidate missed interview notification: $e');
      return false;
    }
  }

  // Handle job approval notification
  Future<bool> handleJobApproval({
    required String jobId,
    required String jobTitle,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Post Approved',
        body: 'Your job post "$jobTitle" has been approved.',
        type: 'job_approval',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling job approval notification: $e');
      return false;
    }
  }

  // Handle subscription renewal notification
  Future<bool> handleSubscriptionRenewal({
    required String subscriptionId,
    required String planName,
    required int daysLeft,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Subscription Renewal Reminder',
        body: 'Your $planName subscription expires in $daysLeft days.',
        type: 'subscription_renewal',
        data: {
          'subscription_id': subscriptionId,
          'plan_name': planName,
          'days_left': daysLeft,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling subscription renewal notification: $e');
      return false;
    }
  }

  // Handle payment successful notification
  Future<bool> handlePaymentSuccessful({
    required String transactionId,
    required String amount,
    required String planName,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Payment Successful',
        body: 'Payment of $amount for $planName was successful.',
        type: 'payment_successful',
        data: {
          'transaction_id': transactionId,
          'amount': amount,
          'plan_name': planName,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling payment successful notification: $e');
      return false;
    }
  }

  // Handle payment failed notification
  Future<bool> handlePaymentFailed({
    required String transactionId,
    required String errorMessage,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Payment Failed',
        body: 'Payment failed: $errorMessage',
        type: 'payment_failed',
        data: {
          'transaction_id': transactionId,
          'error_message': errorMessage,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling payment failed notification: $e');
      return false;
    }
  }

  // Handle invoice ready notification
  Future<bool> handleInvoiceReady({
    required String invoiceId,
    required String invoiceNumber,
    required String amount,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Invoice Ready',
        body: 'Invoice $invoiceNumber for $amount is ready for download.',
        type: 'invoice_ready',
        data: {
          'invoice_id': invoiceId,
          'invoice_number': invoiceNumber,
          'amount': amount,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling invoice ready notification: $e');
      return false;
    }
  }

  // Handle recruiter approval notification
  Future<bool> handleRecruiterApproval({
    required String recruiterId,
    required String companyName,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Account Approved',
        body: 'Your account with $companyName has been approved.',
        type: 'recruiter_approval',
        data: {
          'recruiter_id': recruiterId,
          'company_name': companyName,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling recruiter approval notification: $e');
      return false;
    }
  }

  // Handle job expiry notification
  Future<bool> handleJobExpiry({
    required String jobId,
    required String jobTitle,
    required String expiryDate,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Post Expiring Soon',
        body: 'Your job post "$jobTitle" will expire on $expiryDate.',
        type: 'job_expiry',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'expiry_date': expiryDate,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling job expiry notification: $e');
      return false;
    }
  }

  // Handle new job posted notification
  Future<bool> handleNewJobPosted({
    required String jobId,
    required String jobTitle,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Posted Successfully',
        body: 'Your job post "$jobTitle" has been successfully posted.',
        type: 'new_job_posted',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling new job posted notification: $e');
      return false;
    }
  }

  // Handle job report filed notification
  Future<bool> handleJobReportFiled({
    required String jobId,
    required String jobTitle,
    required String reportReason,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Report Filed',
        body: 'Your job post "$jobTitle" has been reported for: $reportReason',
        type: 'job_report_filed',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'report_reason': reportReason,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling job report filed notification: $e');
      return false;
    }
  }

  // Handle fraudulent job detected notification
  Future<bool> handleFraudulentJobDetected({
    required String jobId,
    required String jobTitle,
    required String reason,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Fraudulent Job Detected',
        body: 'Your job post "$jobTitle" has been flagged as fraudulent: $reason',
        type: 'fraudulent_job_detected',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'reason': reason,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling fraudulent job detected notification: $e');
      return false;
    }
  }

  // Handle job rejected notification
  Future<bool> handleJobRejected({
    required String jobId,
    required String jobTitle,
    required String reason,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Post Rejected',
        body: 'Your job post "$jobTitle" was not approved. Reason: $reason',
        type: 'job_rejected',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'reason': reason,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling job rejection notification: $e');
      return false;
    }
  }

  // Handle account verification pending notification
  Future<bool> handleAccountVerificationPending({
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Account Verification Pending',
        body: 'Your account verification is currently under review by our team.',
        type: 'account_verification_pending',
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling verification pending: $e');
      return false;
    }
  }

  // Handle account verified notification
  Future<bool> handleAccountVerified({
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Recruiter Account Verified',
        body: 'Congratulations! Your recruiter account has been fully verified.',
        type: 'account_verification',
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling recruiter verification: $e');
      return false;
    }
  }

  // Handle account rejected notification
  Future<bool> handleAccountRejected({
    required String reason,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Account Verification Rejected',
        body: 'Your recruiter account verification was rejected. Reason: $reason',
        type: 'account_rejected',
        data: {'reason': reason},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling account rejection: $e');
      return false;
    }
  }

  // Handle account suspended notification
  Future<bool> handleAccountSuspended({
    required String reason,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Account Suspended',
        body: 'Your account has been suspended by the administrator. Reason: $reason',
        type: 'account_suspended',
        data: {'reason': reason},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling account suspension: $e');
      return false;
    }
  }

  // Handle verification documents required notification
  Future<bool> handleVerificationDocumentsRequired({
    required String documentsList,
    required String recipientId, // Recruiter ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Additional Documents Required',
        body: 'Further verification is needed. Please provide: $documentsList',
        type: 'verification_documents_required',
        data: {'documents_list': documentsList},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling documents required: $e');
      return false;
    }
  }

  // Get all recruiter-specific notifications
  Future<Map<String, dynamic>> getRecruiterNotifications({
    required String recruiterId,
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final result = await _notificationService.getUserNotifications(
        page: page,
        limit: limit,
        unreadOnly: unreadOnly,
      );

      if (result['success'] == true) {
        final notifications = (result['notifications'] as List)
            .map((json) => _parseNotification(json))
            .toList();

        // Filter for recruiter-specific notification types
        final recruiterNotifications = notifications.where((notification) =>
            _isRecruiterNotificationType(notification.type)
        ).toList();

        return {
          'success': true,
          'notifications': recruiterNotifications,
          'pagination': result['pagination'],
        };
      }

      return result;
    } catch (e) {
      print('Error getting recruiter notifications: $e');
      return {
        'success': false,
        'notifications': [],
        'message': 'Failed to get recruiter notifications',
      };
    }
  }

  bool _isRecruiterNotificationType(NotificationType type) {
    final recruiterNotificationTypes = {
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

    return recruiterNotificationTypes.contains(type);
  }

  NotificationModel _parseNotification(dynamic json) {
    final isReadRaw = json['is_read'];
    final isArchivedRaw = json['is_archived'];
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? 'New notification',
      type: _getNotificationType(json['type'] ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      isRead: isReadRaw is bool ? isReadRaw : (isReadRaw == 1),
      isArchived: isArchivedRaw is bool ? isArchivedRaw : (isArchivedRaw == 1),
    );
  }

  NotificationType _getNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'application_status':
        return NotificationType.applicationStatus;
      case 'new_job_match':
        return NotificationType.newJobMatch;
      case 'similar_jobs_available':
        return NotificationType.similarJobsAvailable;
      case 'company_hiring_alert':
        return NotificationType.companyHiringAlert;
      case 'job_expiring_soon':
        return NotificationType.jobExpiringSoon;
      case 'profile_view':
        return NotificationType.profileView;
      case 'profile_shortlisted':
        return NotificationType.profileShortlisted;
      case 'resume_viewed':
        return NotificationType.resumeViewed;
      case 'message':
        return NotificationType.message;
      case 'new_application':
        return NotificationType.newApplication;
      case 'welcome':
        return NotificationType.welcome;
      case 'account_verification':
        return NotificationType.accountVerification;
      case 'account_verification_pending':
        return NotificationType.accountVerificationPending;
      case 'account_rejected':
        return NotificationType.accountRejected;
      case 'account_suspended':
        return NotificationType.accountSuspended;
      case 'verification_documents_required':
        return NotificationType.verificationDocumentsRequired;
      case 'password_reset':
        return NotificationType.passwordReset;
      case 'password_changed':
        return NotificationType.passwordChanged;
      case 'interview_scheduled':
        return NotificationType.interviewScheduled;
      case 'offer_extended':
        return NotificationType.offerExtended;
      case 'job_expiry':
        return NotificationType.jobExpiry;
      case 'job_posted':
        return NotificationType.jobPosted;
      case 'job_approved':
        return NotificationType.jobApproval;
      case 'job_rejected':
        return NotificationType.jobRejected;
      case 'new_user_registration':
        return NotificationType.newUserRegistration;
      case 'new_recruiter_registration':
        return NotificationType.newRecruiterRegistration;
      case 'system_maintenance':
        return NotificationType.systemMaintenance;
      case 'platform_update':
        return NotificationType.platformUpdate;
      case 'policy_update':
        return NotificationType.policyUpdate;
      case 'new_feature_announcement':
        return NotificationType.newFeatureAnnouncement;
      case 'emergency_broadcast':
        return NotificationType.emergencyBroadcast;
      case 'holiday_schedule':
        return NotificationType.holidaySchedule;
      case 'candidate_responded':
        return NotificationType.candidateResponded;
      case 'high_profile_candidate_applied':
        return NotificationType.highProfileCandidateApplied;
      case 'candidate_scheduled_interview':
        return NotificationType.candidateScheduledInterview;
      case 'candidate_missed_interview':
        return NotificationType.candidateMissedInterview;
      case 'subscription_renewal':
        return NotificationType.subscriptionRenewal;
      case 'payment_successful':
        return NotificationType.paymentSuccessful;
      case 'payment_failed':
        return NotificationType.paymentFailed;
      case 'invoice_ready':
        return NotificationType.invoiceReady;
      case 'admin_message':
        return NotificationType.adminMessage;
      case 'support_response':
        return NotificationType.supportResponse;
      case 'feature_request':
        return NotificationType.featureRequest;
      case 'user_verification_required':
        return NotificationType.userVerificationRequired;
      case 'suspicious_activity_detected':
        return NotificationType.suspiciousActivityDetected;
      case 'user_reported':
        return NotificationType.userReported;
      case 'account_deletion_request':
        return NotificationType.accountDeletionRequest;
      case 'new_job_posted':
        return NotificationType.newJobPosted;
      case 'job_report_filed':
        return NotificationType.jobReportFiled;
      case 'application_report_filed':
        return NotificationType.applicationReportFiled;
      case 'profile_report_filed':
        return NotificationType.profileReportFiled;
      case 'fraudulent_job_detected':
        return NotificationType.fraudulentJobDetected;
      case 'spam_content_detected':
        return NotificationType.spamContentDetected;
      case 'application_follow_up':
        return NotificationType.applicationFollowUp;
      case 'wishlist_job_update':
        return NotificationType.wishlistJobUpdate;
      case 'system_downtime':
        return NotificationType.systemDowntime;
      case 'performance_issue':
        return NotificationType.performanceIssue;
      case 'security_breach':
        return NotificationType.securityBreach;
      case 'database_backup_complete':
        return NotificationType.databaseBackupComplete;
      case 'server_resource_alert':
        return NotificationType.serverResourceAlert;
      case 'daily_activity_summary':
        return NotificationType.dailyActivitySummary;
      case 'weekly_platform_metrics':
        return NotificationType.weeklyPlatformMetrics;
      case 'monthly_analytics_report':
        return NotificationType.monthlyAnalyticsReport;
      case 'revenue_report':
        return NotificationType.revenueReport;
      case 'user_growth_statistics':
        return NotificationType.userGrowthStatistics;
      case 'new_support_ticket':
        return NotificationType.newSupportTicket;
      case 'escalated_issue':
        return NotificationType.escalatedIssue;
      case 'critical_bug_reported':
        return NotificationType.criticalBugReported;
      case 'privacy_policy_violation':
        return NotificationType.privacyPolicyViolation;
      case 'terms_of_service_violation':
        return NotificationType.termsOfServiceViolation;
      case 'gdpr_compliance_alert':
        return NotificationType.gdprComplianceAlert;
      case 'legal_request_received':
        return NotificationType.legalRequestReceived;
      default:
        return NotificationType.system;
    }
  }
}