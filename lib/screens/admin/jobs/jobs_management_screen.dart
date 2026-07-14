import 'package:airigo_jobportal/models/admin/admin_job_model.dart';
import 'package:airigo_jobportal/services/admin/admin_api_service.dart';
import 'package:airigo_jobportal/services/admin/admin_notification_service.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class JobsManagementScreen extends StatefulWidget {
  const JobsManagementScreen({super.key});

  @override
  State<JobsManagementScreen> createState() => _JobsManagementScreenState();
}

class _JobsManagementScreenState extends State<JobsManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  final AdminNotificationService _notificationService = AdminNotificationService();
  late TabController _tabController;

  List<AdminJobModel> _pendingJobs = [];
  List<AdminJobModel> _allJobs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('JobsManagement: Fetching pending jobs...');
      final pendingResponse = await _apiService.getPendingJobs();
      print('JobsManagement: Pending response: $pendingResponse');

      // Handle different response formats
      List<dynamic> pendingData;
      if (pendingResponse['jobs'] is List) {
        pendingData = pendingResponse['jobs'] as List<dynamic>;
      } else if (pendingResponse['data'] is List) {
        pendingData = pendingResponse['data'] as List<dynamic>;
      } else if (pendingResponse is List) {
        // Response itself is the array
        pendingData = pendingResponse as List<dynamic>;
      } else {
        print('JobsManagement: No pending jobs found in response');
        pendingData = [];
      }
      _pendingJobs = pendingData
          .map((json) => AdminJobModel.fromJson(json))
          .toList();
      print('JobsManagement: Loaded ${_pendingJobs.length} pending jobs');

      print('JobsManagement: Fetching all jobs (page: $_currentPage)...');
      final jobsResponse = await _apiService.getJobs(page: _currentPage);
      print('JobsManagement: All jobs response: $jobsResponse');

      // Handle different response formats
      List<dynamic> jobsData;
      if (jobsResponse['jobs'] is List) {
        jobsData = jobsResponse['jobs'] as List<dynamic>;
      } else if (jobsResponse['data'] is List) {
        jobsData = jobsResponse['data'] as List<dynamic>;
      } else if (jobsResponse is List) {
        // Response itself is the array
        jobsData = jobsResponse as List<dynamic>;
      } else {
        print('JobsManagement: No jobs found in response');
        jobsData = [];
      }
      final pagination =
          jobsResponse['pagination'] ?? jobsResponse['meta'] ?? {};

      _allJobs = jobsData.map((json) => AdminJobModel.fromJson(json)).toList();
      _currentPage = pagination['page'] ?? 1;
      _totalPages = pagination['pages'] ?? pagination['last_page'] ?? 1;

      print(
        'JobsManagement: Loaded ${_allJobs.length} jobs, page $_currentPage of $_totalPages',
      );

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('JobsManagement: Error loading jobs: $e');
      print('JobsManagement: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to load jobs: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveJob(int jobId) async {
    try {
      final result = await _apiService.approveJob(jobId);
      
      // Send notification to recruiter
      try {
        final jobData = result['job'];
        if (jobData != null) {
          await _notificationService.sendJobApprovalNotification(
            jobId: jobId,
            jobTitle: jobData['title'] ?? 'Job',
          );
        }
      } catch (e) {
        print('Failed to send approval notification: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job approved'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadJobs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectJob(int jobId) async {
    try {
      final result = await _apiService.rejectJob(jobId);
      
      // Send notification to recruiter
      try {
        final jobData = result['job'];
        if (jobData != null) {
          await _notificationService.sendJobRejectionNotification(
            jobId: jobId,
            jobTitle: jobData['title'] ?? 'Job',
          );
        }
      } catch (e) {
        print('Failed to send rejection notification: $e');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job rejected'),
          backgroundColor: Colors.red,
        ),
      );
      await _loadJobs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteJob(int jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteJob(jobId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadJobs();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      appBar: AppBar(
        title: const Text('Jobs Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${_pendingJobs.length})'),
            const Tab(text: 'All Jobs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [_buildPendingJobsList(), _buildAllJobsList()],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_jobs_refresh',
        onPressed: _loadJobs,
        backgroundColor: AppTheme.primaryBrand,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64.sp, color: Colors.red),
          SizedBox(height: 16.h),
          const Text('Failed to load jobs'),
          SizedBox(height: 16.h),
          ElevatedButton(onPressed: _loadJobs, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildPendingJobsList() {
    if (_pendingJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.tick_circle, size: 64.sp, color: Colors.green),
            SizedBox(height: 16.h),
            const Text('No pending jobs for approval'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _pendingJobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(_pendingJobs[index], isPending: true);
        },
      ),
    );
  }

  Widget _buildAllJobsList() {
    if (_allJobs.isEmpty) {
      return const Center(child: Text('No jobs found'));
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _allJobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(_allJobs[index], isPending: false);
        },
      ),
    );
  }

  Widget _buildJobCard(AdminJobModel job, {required bool isPending}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (job.companyLogoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: job.companyLogoUrl!,
                      width: 50.w,
                      height: 50.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (job.companyLogoUrl == null)
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Iconsax.building, color: AppTheme.primaryBrand),
                  ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.designation,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        job.companyName,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildApprovalBadge(job.approvalStatus),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Icon(Iconsax.location, size: 16.sp, color: Colors.grey),
                SizedBox(width: 4.w),
                Text(
                  job.location,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(width: 12.w),
                Icon(Iconsax.money, size: 16.sp, color: Colors.grey),
                SizedBox(width: 4.w),
                Text(
                  job.ctc,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    job.jobType,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.yellow,
                    ),
                  ),
                ),
                if (job.isUrgentHiring) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Urgent',
                      style: TextStyle(fontSize: 10.sp, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showJobDetails(job),
                  icon: Icon(
                    Iconsax.eye,
                    size: 16.sp,
                    color: context.theme.colorScheme.onSurface,
                  ),
                  label: Text(
                    'View',
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isPending || job.approvalStatus == 'pending') ...[
                  SizedBox(width: 8.w),
                  ElevatedButton.icon(
                    onPressed: () => _approveJob(job.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  OutlinedButton.icon(
                    onPressed: () => _rejectJob(job.id),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
                if (!isPending && job.approvalStatus == 'approved') ...[
                  SizedBox(width: 8.w),
                  OutlinedButton.icon(
                    onPressed: () => _deleteJob(job.id),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showJobDetails(AdminJobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with company logo
                  Row(
                    children: [
                      if (job.companyLogoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: CachedNetworkImage(
                            imageUrl: job.companyLogoUrl!,
                            width: 60.w,
                            height: 60.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (job.companyLogoUrl == null)
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrand.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Iconsax.building,
                            size: 30.sp,
                            color: AppTheme.primaryBrand,
                          ),
                        ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.designation,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              job.companyName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Job Details Section
                  Text(
                    'Job Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow('Category', job.category),
                  _buildDetailRow('Job Type', job.jobType),
                  _buildDetailRow('CTC', job.ctc),
                  _buildDetailRow('Location', job.location),
                  if (job.experienceRequired != null)
                    _buildDetailRow(
                      'Experience Required',
                      job.experienceRequired!,
                    ),
                  _buildDetailRow(
                    'Approval Status',
                    job.approvalStatus.toUpperCase(),
                    valueColor: job.approvalStatus == 'approved'
                        ? Colors.green
                        : job.approvalStatus == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                  ),
                  _buildDetailRow(
                    'Status',
                    job.isActive ? 'Active' : 'Inactive',
                    valueColor: job.isActive ? Colors.green : Colors.red,
                  ),
                  if (job.isUrgentHiring)
                    Container(
                      margin: EdgeInsets.only(top: 8.h),
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 16.sp,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Urgent Hiring',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Company Information Section
                  Text(
                    'Company Information',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow('Company Name', job.companyName),
                  if (job.companyUrl != null)
                    _buildDetailRowWithAction(
                      'Company Website',
                      job.companyUrl!,
                      actionText: 'Visit',
                      onTap: () async {
                        // TODO: Open company website
                        print('Visit: ${job.companyUrl}');
                      },
                    ),
                  if (job.recruiterName != null)
                    _buildDetailRow('Recruiter', job.recruiterName!),
                  if (job.recruiterEmail != null)
                    _buildDetailRow('Recruiter Email', job.recruiterEmail!),
                  if (job.applicationCount != null)
                    _buildDetailRow(
                      'Total Applications',
                      '${job.applicationCount}',
                    ),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Description Section
                  if (job.description != null) ...[
                    Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      job.description!,
                      style: TextStyle(fontSize: 14.sp, height: 1.5),
                    ),
                    SizedBox(height: 16.h),
                    Divider(),
                    SizedBox(height: 16.h),
                  ],

                  // Requirements Section
                  if (job.requirements != null &&
                      job.requirements!.isNotEmpty) ...[
                    Text(
                      'Requirements',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...job.requirements!.map((req) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.tick_circle,
                              size: 16.sp,
                              color: AppTheme.primaryBrand,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                req,
                                style: TextStyle(fontSize: 13.sp),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 16.h),
                    Divider(),
                    SizedBox(height: 16.h),
                  ],

                  // Skills Section
                  if (job.skillsRequired != null &&
                      job.skillsRequired!.isNotEmpty) ...[
                    Text(
                      'Required Skills',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: job.skillsRequired!.map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: AppTheme.primaryBrand.withOpacity(
                            0.1,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),
                    Divider(),
                    SizedBox(height: 16.h),
                  ],

                  // Perks & Benefits Section
                  if (job.perksAndBenefits != null &&
                      job.perksAndBenefits!.isNotEmpty) ...[
                    Text(
                      'Perks & Benefits',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...job.perksAndBenefits!.map((perk) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.star,
                              size: 16.sp,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                perk,
                                style: TextStyle(fontSize: 13.sp),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 16.h),
                    Divider(),
                    SizedBox(height: 16.h),
                  ],

                  // Timestamps Section
                  Text(
                    'Posted Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    'Posted At',
                    DateFormat('dd MMM yyyy, hh:mm a').format(job.createdAt),
                  ),
                  _buildDetailRow(
                    'Last Updated',
                    DateFormat('dd MMM yyyy, hh:mm a').format(job.updatedAt),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithAction(
    String label,
    String value, {
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.primaryBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(actionText)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
