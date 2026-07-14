// ============================================================
// screens/common/apply_job_modal.dart
// Job application modal with real API integration
// ============================================================

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:airigo_jobportal/models/job_model.dart';
import 'package:airigo_jobportal/services/api/application_service.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApplyJobModal extends StatefulWidget {
  final JobModel job;
  final String? jobseekerName;
  final String? jobseekerSkills;
  final String? resumeUrl;
  final String? resumeFilename;
  final VoidCallback? onSuccess;

  const ApplyJobModal({
    super.key,
    required this.job,
    this.jobseekerName,
    this.jobseekerSkills,
    this.resumeUrl,
    this.resumeFilename,
    this.onSuccess,
  });

  @override
  State<ApplyJobModal> createState() => _ApplyJobModalState();
}

class _ApplyJobModalState extends State<ApplyJobModal>
    with TickerProviderStateMixin {
  final ApplicationService _applicationService = ApplicationService();
  final TextEditingController _coverCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;
  late AnimationController _successCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _coverCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (_isSubmitting) return;

    debugPrint('========== APPLY JOB MODAL SUBMIT STARTED ==========');
    debugPrint(
      'Job ID: ${widget.job.id}, Designation: ${widget.job.designation}',
    );
    debugPrint(
      'Company: ${widget.job.companyName}, Location: ${widget.job.location}',
    );
    debugPrint('Jobseeker Name: ${widget.jobseekerName}');
    debugPrint('Jobseeker Skills: ${widget.jobseekerSkills}');
    debugPrint('Resume URL: ${widget.resumeUrl}');
    debugPrint('Resume Filename: ${widget.resumeFilename}');
    debugPrint('Cover Letter Length: ${_coverCtrl.text.length} characters');
    debugPrint(
      'Cover Letter Text: ${_coverCtrl.text.isNotEmpty ? _coverCtrl.text : "(empty)"}',
    );
    debugPrint('=================================================');

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
        '_submitApplication: Calling ApplicationService.applyForJob...',
      );

      final result = await _applicationService.applyForJob(
        jobId: widget.job.id.toString(),
        coverLetter: _coverCtrl.text.isNotEmpty ? _coverCtrl.text : null,
      );

      debugPrint('_submitApplication: Response received: $result');

      if (result['success'] == true) {
        debugPrint('_submitApplication: SUCCESS! Application submitted');
        debugPrint('_submitApplication: Message: ${result['message']}');

        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
        _successCtrl.forward();
        widget.onSuccess?.call();

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          debugPrint('_submitApplication: Closing modal');
          Navigator.pop(context);
        }
      } else {
        debugPrint('_submitApplication: FAILED - ${result['message']}');
        setState(() {
          _isSubmitting = false;
          _errorMessage = result['message'] ?? 'Failed to submit application';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('_submitApplication: EXCEPTION occurred: $e');
      debugPrint('_submitApplication: Stack trace: $stackTrace');
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }

    debugPrint('========== APPLY JOB MODAL SUBMIT COMPLETED ==========');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('========== APPLYJOB MODAL BUILD ==========');
    debugPrint(
      'Job ID: ${widget.job.id}, Designation: ${widget.job.designation}',
    );
    debugPrint('Jobseeker Name: "${widget.jobseekerName}"');
    debugPrint('Jobseeker Skills: "${widget.jobseekerSkills}"');
    debugPrint('Resume URL: "${widget.resumeUrl}"');
    debugPrint('Resume Filename: "${widget.resumeFilename}"');
    debugPrint('=====================================');

    final isDark = context.isDark;
    final hasResume = widget.resumeUrl != null && widget.resumeUrl!.isNotEmpty;
    debugPrint('Has Resume: $hasResume');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24.w,
        16.h,
        24.w,
        MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      child: _isSuccess
          ? _SuccessView(scaleAnim: _scaleAnim, fadeAnim: _fadeAnim)
          : _ApplicationForm(
              job: widget.job,
              jobseekerName: widget.jobseekerName,
              jobseekerSkills: widget.jobseekerSkills,
              resumeUrl: widget.resumeUrl,
              resumeFilename: widget.resumeFilename,
              coverCtrl: _coverCtrl,
              isSubmitting: _isSubmitting,
              errorMessage: _errorMessage,
              onSubmit: _submitApplication,
            ),
    );
  }
}

class _ApplicationForm extends StatelessWidget {
  final JobModel job;
  final String? jobseekerName;
  final String? jobseekerSkills;
  final String? resumeUrl;
  final String? resumeFilename;
  final TextEditingController coverCtrl;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _ApplicationForm({
    required this.job,
    this.jobseekerName,
    this.jobseekerSkills,
    this.resumeUrl,
    this.resumeFilename,
    required this.coverCtrl,
    required this.isSubmitting,
    this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hasResume = resumeUrl != null && resumeUrl!.isNotEmpty;

    // Add logging for debugging
    debugPrint(
      'ApplyJobModal: Building form - hasResume: $hasResume, resumeUrl: $resumeUrl, resumeFilename: $resumeFilename',
    );
    debugPrint(
      'ApplyJobModal: Jobseeker: $jobseekerName, Skills: $jobseekerSkills',
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply for Position',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${job.designation} at ${job.companyName}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  job.ctcRange,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          Text('Your Resume', style: context.textTheme.titleMedium),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: hasResume
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasResume
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: hasResume
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    hasResume
                        ? Icons.description_rounded
                        : Icons.warning_rounded,
                    color: hasResume ? AppColors.success : AppColors.error,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resumeFilename ??
                            (jobseekerName != null
                                ? '${jobseekerName!.split(' ').first}_Resume.pdf'
                                : 'My_Resume.pdf'),
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        hasResume ? 'Ready to submit' : 'No resume uploaded',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: hasResume
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasResume)
                  TextButton(
                    onPressed: () =>
                        context.showSnackBar('Update resume in profile'),
                    child: Text(
                      'Add Resume',
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp),
                    ),
                  ),
              ],
            ),
          ),

          if (!hasResume) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'No resume found in your profile. Please upload one in your profile settings to apply for jobs.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16.h),

          Text('Cover Letter (optional)', style: context.textTheme.titleMedium),
          SizedBox(height: 8.h),
          TextFormField(
            controller: coverCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Tell the recruiter why you\'re a great fit for this role...',
              hintStyle: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),

          SizedBox(height: 12.h),

          if (jobseekerName != null)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.w,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      jobseekerName!.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobseekerName!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (jobseekerSkills != null)
                          Text(
                            jobseekerSkills!,
                            style: context.textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.secondary,
                    size: 18.sp,
                  ),
                ],
              ),
            ),

          if (errorMessage != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasResume && !isSubmitting ? onSubmit : null,
              icon: isSubmitting
                  ? SizedBox(
                      height: 18.h,
                      width: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.bolt_rounded, color: Colors.white),
              label: Text(
                isSubmitting ? 'Submitting...' : 'Submit Application',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasResume ? AppColors.success : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;

  const _SuccessView({required this.scaleAnim, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 56.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Application Submitted!',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'We\'ll notify you when the recruiter responds.\nGood luck!',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
