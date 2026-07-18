import 'package:airigo_jobportal/services/admin/admin_notification_service.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  final AdminNotificationService _notificationService = AdminNotificationService();

  // Controllers for form inputs
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _maintenanceStartController = TextEditingController();
  final TextEditingController _maintenanceDurationController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  
  String _selectedUserType = 'all'; // 'all', 'jobseeker', 'recruiter', 'admin'
  String _selectedNotificationType = 'general'; // 'general', 'job_approval', 'job_rejection', 'recruiter_approval', 'recruiter_rejection', 'system_maintenance'
  String _selectedJobId = '';

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _reasonController.dispose();
    _maintenanceStartController.dispose();
    _maintenanceDurationController.dispose();
    _jobTitleController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      if (_selectedNotificationType != 'job_approval' && 
          _selectedNotificationType != 'job_rejection' && 
          _selectedNotificationType != 'recruiter_approval' && 
          _selectedNotificationType != 'recruiter_rejection') {
        AppScaffoldFeedback.show(
          context,
          message: 'Please enter title and body',
          type: ResponseType.warning,
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result = {};
      
      switch (_selectedNotificationType) {
        case 'general':
          if (_selectedUserType == 'all') {
            result = await _notificationService.sendNotificationToAll(
              title: _titleController.text,
              body: _bodyController.text,
            );
          } else if (_selectedUserType == 'jobseeker' || _selectedUserType == 'recruiter' || _selectedUserType == 'admin') {
            result = await _notificationService.sendNotificationByRole(
              userType: _selectedUserType,
              title: _titleController.text,
              body: _bodyController.text,
            );
          } else {
            // Specific user notification - need to get user ID from input
            String userIdText = _userIdController.text;
            if (userIdText.isEmpty) {
              AppScaffoldFeedback.show(
                context,
                message: 'Please enter User ID',
                type: ResponseType.warning,
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
            int userId = int.tryParse(userIdText) ?? 0;
            if (userId == 0) {
              AppScaffoldFeedback.show(
                context,
                message: 'Please enter a valid User ID',
                type: ResponseType.warning,
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
            result = await _notificationService.sendNotificationToUser(
              userId: userId,
              title: _titleController.text,
              body: _bodyController.text,
            );
          }
          break;
        case 'job_approval':
          String jobIdText = _selectedJobId;
          String jobTitle = _jobTitleController.text;
          if (jobIdText.isEmpty || jobTitle.isEmpty) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter Job ID and Job Title',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          int jobId = int.tryParse(jobIdText) ?? 0;
          if (jobId == 0) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter a valid Job ID',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          result = await _notificationService.sendJobApprovalNotification(
            jobId: jobId,
            jobTitle: jobTitle,
          );
          break;
        case 'job_rejection':
          String rejJobIdText = _selectedJobId;
          String rejJobTitle = _jobTitleController.text;
          String reason = _reasonController.text;
          if (rejJobIdText.isEmpty || rejJobTitle.isEmpty || reason.isEmpty) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter Job ID, Job Title, and Reason',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          int rejJobId = int.tryParse(rejJobIdText) ?? 0;
          if (rejJobId == 0) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter a valid Job ID',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          result = await _notificationService.sendJobRejectionNotification(
            jobId: rejJobId,
            jobTitle: rejJobTitle,
            reason: reason,
          );
          break;
        case 'recruiter_approval':
          String recUserIdText = _userIdController.text;
          if (recUserIdText.isEmpty) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter User ID',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          int recUserId = int.tryParse(recUserIdText) ?? 0;
          if (recUserId == 0) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter a valid User ID',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          result = await _notificationService.sendRecruiterApprovalNotification(
            userId: recUserId,
          );
          break;
        case 'recruiter_rejection':
          String rejUserIdText = _userIdController.text;
          String rejReason = _reasonController.text;
          if (rejUserIdText.isEmpty || rejReason.isEmpty) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter User ID and Reason',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          int rejUserId = int.tryParse(rejUserIdText) ?? 0;
          if (rejUserId == 0) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter a valid User ID',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          result = await _notificationService.sendRecruiterRejectionNotification(
            userId: rejUserId,
            reason: rejReason,
          );
          break;
        case 'system_maintenance':
          String maintTitle = _titleController.text;
          String maintBody = _bodyController.text;
          String maintStart = _maintenanceStartController.text;
          String maintDuration = _maintenanceDurationController.text;
          
          if (maintTitle.isEmpty || maintBody.isEmpty || maintStart.isEmpty || maintDuration.isEmpty) {
            AppScaffoldFeedback.show(
              context,
              message: 'Please enter all maintenance information',
              type: ResponseType.warning,
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          result = await _notificationService.sendSystemMaintenanceNotification(
            title: maintTitle,
            body: maintBody,
            maintenanceStartTime: maintStart,
            maintenanceDuration: maintDuration,
          );
          break;
      }

      if (result['success'] == true) {
        AppScaffoldFeedback.show(
          context,
          message: result['message'] ?? 'Notification sent successfully',
          type: ResponseType.success,
        );
        _clearForm();
      } else {
        AppScaffoldFeedback.show(
          context,
          message: result['message'] ?? 'Failed to send notification',
          type: ResponseType.error,
        );
      }
    } catch (e) {
      AppScaffoldFeedback.show(
        context,
        message: 'Error: $e',
        type: ResponseType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    _reasonController.clear();
    _maintenanceStartController.clear();
    _maintenanceDurationController.clear();
    _jobTitleController.clear();
    _userIdController.clear();
    setState(() {
      _selectedUserType = 'all';
      _selectedNotificationType = 'general';
      _selectedJobId = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Notifications'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Notifications',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            
            // Notification Type Selector
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
              ),
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Type',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 10.h),
                    DropdownButtonFormField<String>(
                      value: _selectedNotificationType,
                      decoration: const InputDecoration(
                        labelText: 'Select Notification Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'general',
                          child: Text('General Notification'),
                        ),
                        const DropdownMenuItem(
                          value: 'job_approval',
                          child: Text('Job Approval'),
                        ),
                        const DropdownMenuItem(
                          value: 'job_rejection',
                          child: Text('Job Rejection'),
                        ),
                        const DropdownMenuItem(
                          value: 'recruiter_approval',
                          child: Text('Recruiter Approval'),
                        ),
                        const DropdownMenuItem(
                          value: 'recruiter_rejection',
                          child: Text('Recruiter Rejection'),
                        ),
                        const DropdownMenuItem(
                          value: 'system_maintenance',
                          child: Text('System Maintenance'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedNotificationType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // User Type Selector (only for general notifications)
            if (_selectedNotificationType == 'general') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient Type',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      DropdownButtonFormField<String>(
                        value: _selectedUserType,
                        decoration: const InputDecoration(
                          labelText: 'Select Recipient Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All Users'),
                          ),
                          const DropdownMenuItem(
                            value: 'jobseeker',
                            child: Text('Job Seekers'),
                          ),
                          const DropdownMenuItem(
                            value: 'recruiter',
                            child: Text('Recruiters'),
                          ),
                          const DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admins'),
                          ),
                          const DropdownMenuItem(
                            value: 'specific',
                            child: Text('Specific User'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedUserType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // User ID Input (for specific user notifications)
            if (_selectedNotificationType == 'general' && _selectedUserType == 'specific') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ID',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _userIdController,
                        decoration: const InputDecoration(
                          labelText: 'Enter User ID',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // Job ID Input (for job-related notifications)
            if (_selectedNotificationType == 'job_approval' || _selectedNotificationType == 'job_rejection') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job ID',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Enter Job ID',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _selectedJobId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Title',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _jobTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Job Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // User ID Input (for recruiter-related notifications)
            if (_selectedNotificationType == 'recruiter_approval' || _selectedNotificationType == 'recruiter_rejection') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ID',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _userIdController,
                        decoration: const InputDecoration(
                          labelText: 'Enter User ID',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // Title Input (not for job/recruiter approval/rejection)
            if (_selectedNotificationType != 'job_approval' && 
                _selectedNotificationType != 'job_rejection' && 
                _selectedNotificationType != 'recruiter_approval' && 
                _selectedNotificationType != 'recruiter_rejection') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Enter notification title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // Body Input (not for job/recruiter approval/rejection)
            if (_selectedNotificationType != 'job_approval' && 
                _selectedNotificationType != 'job_rejection' && 
                _selectedNotificationType != 'recruiter_approval' && 
                _selectedNotificationType != 'recruiter_rejection') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _bodyController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Enter notification body',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // Reason Input (for rejection notifications)
            if (_selectedNotificationType == 'job_rejection' || _selectedNotificationType == 'recruiter_rejection') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Enter reason for rejection',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // Maintenance Info Input (for system maintenance notifications)
            if (_selectedNotificationType == 'system_maintenance') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                ),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance Info',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _maintenanceStartController,
                        decoration: const InputDecoration(
                          labelText: 'Maintenance Start Time (e.g., 2023-01-01 10:00)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: _maintenanceDurationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (e.g., 2 hours)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
            ],
            
            // Send Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isLoading 
                    ? SizedBox(
                        height: 24.h,
                        width: 24.h,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Send Notification', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Clear Form Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _clearForm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : AppColors.textDark,
                  side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Clear Form', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}