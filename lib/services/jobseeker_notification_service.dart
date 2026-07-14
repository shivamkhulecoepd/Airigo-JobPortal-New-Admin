import 'package:airigo_jobportal/services/api/notification_service.dart';
import 'package:airigo_jobportal/core/service_locator.dart';
import 'package:airigo_jobportal/models/notification_model.dart';

class JobseekerNotificationService {
  final NotificationService _notificationService = getIt<NotificationService>();

  // Handle application status update notification
  Future<bool> handleApplicationStatusUpdate({
    required String applicationId,
    required String jobTitle,
    required String status,
    required String statusMessage,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Application Status Update',
        body: 'Your application for $jobTitle has been updated to: $status',
        type: 'application_status',
        data: {
          'application_id': applicationId,
          'job_title': jobTitle,
          'status': status,
          'status_message': statusMessage,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling application status update notification: $e');
      return false;
    }
  }

  // Handle new job match notification
  Future<bool> handleNewJobMatch({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required String matchPercentage,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'New Job Match Found',
        body: 'We found a new job that matches your profile: $jobTitle at $companyName ($matchPercentage match)',
        type: 'new_job_match',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'company_name': companyName,
          'match_percentage': matchPercentage,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling new job match notification: $e');
      return false;
    }
  }

  // Handle profile view notification
  Future<bool> handleProfileView({
    required String companyId,
    required String companyName,
    required String recruiterName,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Profile Viewed',
        body: 'Your profile was viewed by $recruiterName from $companyName',
        type: 'profile_view',
        data: {
          'company_id': companyId,
          'company_name': companyName,
          'recruiter_name': recruiterName,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling profile view notification: $e');
      return false;
    }
  }

  // Handle message notification
  Future<bool> handleMessage({
    required String senderId,
    required String senderName,
    required String messageContent,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'New Message from $senderName',
        body: messageContent,
        type: 'message',
        data: {
          'sender_id': senderId,
          'sender_name': senderName,
          'message_content': messageContent,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling message notification: $e');
      return false;
    }
  }

  // Handle interview scheduled notification
  Future<bool> handleInterviewScheduled({
    required String interviewId,
    required String jobTitle,
    required String interviewDate,
    required String interviewTime,
    required String interviewLocation,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Interview Scheduled',
        body: 'Your interview for $jobTitle is scheduled for $interviewDate at $interviewTime',
        type: 'interview_scheduled',
        data: {
          'interview_id': interviewId,
          'job_title': jobTitle,
          'interview_date': interviewDate,
          'interview_time': interviewTime,
          'interview_location': interviewLocation,
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
    required String offerId,
    required String jobTitle,
    required String companyName,
    required String salary,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Offer Extended',
        body: 'Congratulations! $companyName has extended a job offer for $jobTitle',
        type: 'offer_extended',
        data: {
          'offer_id': offerId,
          'job_title': jobTitle,
          'company_name': companyName,
          'salary': salary,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling offer extended notification: $e');
      return false;
    }
  }

  // Handle job expiry notification
  Future<bool> handleJobExpiry({
    required String jobId,
    required String jobTitle,
    required String expiryDate,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Post Expired',
        body: 'The job posting "$jobTitle" has expired on $expiryDate',
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

  // Handle welcome notification
  Future<bool> handleWelcome({
    required String userName,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Welcome to Airigo Jobs!',
        body: 'Welcome $userName! We\'re excited to have you on board.',
        type: 'welcome',
        data: {
          'user_name': userName,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling welcome notification: $e');
      return false;
    }
  }

  // Handle account verification notification
  Future<bool> handleAccountVerification({
    required String userName,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Account Verified',
        body: 'Your account has been successfully verified, $userName!',
        type: 'account_verification',
        data: {
          'user_name': userName,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling account verification notification: $e');
      return false;
    }
  }

  // Handle password reset notification
  Future<bool> handlePasswordReset({
    required String userName,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Password Reset Successful',
        body: 'Your password has been successfully reset, $userName.',
        type: 'password_reset',
        data: {
          'user_name': userName,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling password reset notification: $e');
      return false;
    }
  }

  // Handle candidate responded notification (when recruiter responds to jobseeker)
  Future<bool> handleCandidateResponse({
    required String jobId,
    required String jobTitle,
    required String message,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Response from $jobTitle',
        body: 'Recruiter responded: $message',
        type: 'candidate_responded',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'message': message,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling candidate response notification: $e');
      return false;
    }
  }

  // Handle candidate scheduled interview notification
  Future<bool> handleCandidateScheduledInterview({
    required String jobId,
    required String jobTitle,
    required String interviewDate,
    required String interviewTime,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Interview Scheduled',
        body: 'Your interview for $jobTitle has been scheduled for $interviewDate at $interviewTime',
        type: 'candidate_scheduled_interview',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'interview_date': interviewDate,
          'interview_time': interviewTime,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling candidate scheduled interview notification: $e');
      return false;
    }
  }

  // Handle candidate missed interview notification
  Future<bool> handleCandidateMissedInterview({
    required String jobId,
    required String jobTitle,
    required String interviewDate,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Interview Missed',
        body: 'You missed your scheduled interview for $jobTitle on $interviewDate',
        type: 'candidate_missed_interview',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'interview_date': interviewDate,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling candidate missed interview notification: $e');
      return false;
    }
  }

  // Handle new job posted notification (relevant for jobseekers)
  Future<bool> handleNewJobPosted({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'New Job Posted',
        body: 'New job posted: $jobTitle at $companyName',
        type: 'new_job_posted',
        data: {
          'job_id': jobId,
          'job_title': jobTitle,
          'company_name': companyName,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling new job posted notification: $e');
      return false;
    }
  }

  // Handle job report filed notification (when jobseeker reports a job)
  Future<bool> handleJobReportFiled({
    required String jobId,
    required String jobTitle,
    required String reportReason,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Report Submitted',
        body: 'Your report for job "$jobTitle" has been submitted: $reportReason',
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

  // Handle application report filed notification (when jobseeker reports another application)
  Future<bool> handleApplicationReportFiled({
    required String applicationId,
    required String jobTitle,
    required String reportReason,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Application Report Submitted',
        body: 'Your report for application to "$jobTitle" has been submitted: $reportReason',
        type: 'application_report_filed',
        data: {
          'application_id': applicationId,
          'job_title': jobTitle,
          'report_reason': reportReason,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling application report filed notification: $e');
      return false;
    }
  }

  // Handle profile report filed notification (when jobseeker's profile is reported)
  Future<bool> handleProfileReportFiled({
    required String recipientId, // Jobseeker ID
    required String reportReason,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Profile Report Received',
        body: 'Your profile has been reported: $reportReason',
        type: 'profile_report_filed',
        data: {
          'report_reason': reportReason,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling profile report filed notification: $e');
      return false;
    }
  }

  // Handle fraudulent job detected notification (warning to jobseekers)
  Future<bool> handleFraudulentJobDetected({
    required String jobId,
    required String jobTitle,
    required String reason,
    required String recipientId, // Jobseeker ID
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Fraudulent Job Warning',
        body: 'Job "$jobTitle" has been flagged as fraudulent: $reason',
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

  // Handle user verification required notification
  Future<bool> handleUserVerificationRequired({
    required String recipientId, // Jobseeker ID
    required String verificationType,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Verification Required',
        body: 'Your $verificationType verification is required to continue using the platform',
        type: 'user_verification_required',
        data: {
          'verification_type': verificationType,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling user verification required notification: $e');
      return false;
    }
  }

  // Handle suspicious activity detected notification
  Future<bool> handleSuspiciousActivityDetected({
    required String recipientId, // Jobseeker ID
    required String activityDescription,
    required String timestamp,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Suspicious Activity Detected',
        body: 'Suspicious activity detected on your account: $activityDescription at $timestamp',
        type: 'suspicious_activity_detected',
        data: {
          'activity_description': activityDescription,
          'timestamp': timestamp,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling suspicious activity detected notification: $e');
      return false;
    }
  }

  // Handle user reported notification
  Future<bool> handleUserReported({
    required String recipientId, // Jobseeker ID
    required String reporterId,
    required String reportReason,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'You Have Been Reported',
        body: 'Another user has reported you: $reportReason',
        type: 'user_reported',
        data: {
          'reporter_id': reporterId,
          'report_reason': reportReason,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling user reported notification: $e');
      return false;
    }
  }

  // Handle account deletion request notification
  Future<bool> handleAccountDeletionRequest({
    required String recipientId, // Jobseeker ID
    required String requestReason,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Account Deletion Request',
        body: 'An account deletion request has been submitted: $requestReason',
        type: 'account_deletion_request',
        data: {
          'request_reason': requestReason,
        },
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling account deletion request notification: $e');
      return false;
    }
  }

  // Handle similar jobs available notification
  Future<bool> handleSimilarJobsAvailable({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Similar Jobs Available',
        body: 'Interested in $jobTitle? Check out similar positions at $companyName.',
        type: 'similar_jobs_available',
        data: {'job_id': jobId, 'job_title': jobTitle, 'company_name': companyName},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling similar jobs available: $e');
      return false;
    }
  }

  // Handle company hiring alert notification
  Future<bool> handleCompanyHiringAlert({
    required String companyId,
    required String companyName,
    required String jobTitle,
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Company Hiring Alert',
        body: '$companyName just posted a new job: $jobTitle',
        type: 'company_hiring_alert',
        data: {'company_id': companyId, 'company_name': companyName, 'job_title': jobTitle},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling company hiring alert: $e');
      return false;
    }
  }

  // Handle job expiring soon notification
  Future<bool> handleJobExpiringSoon({
    required String jobId,
    required String jobTitle,
    required String expiryTime,
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Job Expiring Soon',
        body: 'The job "$jobTitle" you applied to is closing in $expiryTime',
        type: 'job_expiring_soon',
        data: {'job_id': jobId, 'job_title': jobTitle},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling job expiring soon: $e');
      return false;
    }
  }

  // Handle profile shortlisted notification
  Future<bool> handleProfileShortlisted({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Profile Shortlisted!',
        body: 'Great news! Your profile has been shortlisted for $jobTitle at $companyName',
        type: 'profile_shortlisted',
        data: {'job_id': jobId, 'job_title': jobTitle, 'company_name': companyName},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling profile shortlisted: $e');
      return false;
    }
  }

  // Handle resume viewed notification
  Future<bool> handleResumeViewed({
    required String recruiterName,
    required String companyName,
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Resume Viewed',
        body: '$recruiterName from $companyName viewed your resume',
        type: 'resume_viewed',
        data: {'recruiter_name': recruiterName, 'company_name': companyName},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling resume viewed: $e');
      return false;
    }
  }

  // Handle password changed notification
  Future<bool> handlePasswordChanged({
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Password Changed Successfully',
        body: 'Your account password has been changed successfully.',
        type: 'password_changed',
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling password changed: $e');
      return false;
    }
  }

  // Handle application follow-up notification
  Future<bool> handleApplicationFollowUp({
    required String applicationId,
    required String jobTitle,
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Follow-up Reminder',
        body: 'It\'s been a while since you applied to $jobTitle. Consider following up with the recruiter.',
        type: 'application_follow_up',
        data: {'application_id': applicationId, 'job_title': jobTitle},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling application follow-up: $e');
      return false;
    }
  }

  // Handle wishlist job updates notification
  Future<bool> handleWishlistJobUpdate({
    required String jobId,
    required String jobTitle,
    required String updateType,
    required String recipientId,
  }) async {
    try {
      final result = await _notificationService.sendNotification(
        recipientId: recipientId,
        title: 'Wishlist Update',
        body: 'Update for "$jobTitle" in your wishlist: $updateType',
        type: 'wishlist_job_update',
        data: {'job_id': jobId, 'job_title': jobTitle, 'update_type': updateType},
      );
      return result['success'] ?? false;
    } catch (e) {
      print('Error handling wishlist job update: $e');
      return false;
    }
  }

  // Get all jobseeker-specific notifications
  Future<Map<String, dynamic>> getJobseekerNotifications({
    required String jobseekerId,
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

        // Filter for jobseeker-specific notification types
        final jobseekerNotifications = notifications.where((notification) =>
            _isJobseekerNotificationType(notification.type)
        ).toList();

        return {
          'success': true,
          'notifications': jobseekerNotifications,
          'pagination': result['pagination'],
        };
      }

      return result;
    } catch (e) {
      print('Error getting jobseeker notifications: $e');
      return {
        'success': false,
        'notifications': [],
        'message': 'Failed to get jobseeker notifications',
      };
    }
  }

  bool _isJobseekerNotificationType(NotificationType type) {
    final jobseekerNotificationTypes = {
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
      NotificationType.jobReportFiled,
      NotificationType.applicationReportFiled,
      NotificationType.profileReportFiled,
      NotificationType.fraudulentJobDetected,
      NotificationType.userVerificationRequired,
      NotificationType.suspiciousActivityDetected,
      NotificationType.userReported,
      NotificationType.accountDeletionRequest,
      NotificationType.applicationFollowUp,
      NotificationType.wishlistJobUpdate,
      NotificationType.newFeatureAnnouncement,
      NotificationType.emergencyBroadcast,
      NotificationType.holidaySchedule,
      NotificationType.systemMaintenance,
      NotificationType.platformUpdate,
      NotificationType.policyUpdate,
    };

    return jobseekerNotificationTypes.contains(type);
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