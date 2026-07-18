import 'package:airigo_jobportal/models/admin/admin_user_model.dart';
import 'package:airigo_jobportal/services/admin/admin_api_service.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/utils/theme.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:airigo_jobportal/widgets/shimmer_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class JobseekersManagementScreen extends StatefulWidget {
  const JobseekersManagementScreen({super.key});

  @override
  State<JobseekersManagementScreen> createState() =>
      _JobseekersManagementScreenState();
}

class _JobseekersManagementScreenState
    extends State<JobseekersManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminUserModel> _jobseekers = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadJobseekers();
  }

  Future<void> _loadJobseekers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print(
        'JobseekersManagement: Fetching jobseekers (page: $_currentPage)...',
      );
      final response = await _apiService.getJobseekers(
        page: _currentPage,
        limit: 10,
        search: _searchQuery,
      );
      print('JobseekersManagement: Response: $response');

      // Handle different response formats
      List<dynamic> data;
      if (response['data'] is List) {
        data = response['data'] as List<dynamic>;
      } else if (response['jobseekers'] is List) {
        data = response['jobseekers'] as List<dynamic>;
      } else if (response is List) {
        data = response as List<dynamic>;
      } else {
        print('JobseekersManagement: No jobseekers data found in response');
        data = [];
      }

      final pagination = response['pagination'] ?? response['meta'] ?? {};

      print('JobseekersManagement: Loaded ${data.length} jobseekers');

      if (mounted) {
        setState(() {
          _jobseekers = data
              .map((json) => AdminUserModel.fromJson(json))
              .toList();
          _currentPage = pagination['page'] ?? 1;
          _totalPages = pagination['pages'] ?? pagination['last_page'] ?? 1;
          _totalItems = pagination['total'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('JobseekersManagement: Error loading jobseekers: $e');
      print('JobseekersManagement: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to load jobseekers: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchJobseekers() async {
    setState(() {
      _searchQuery = _searchController.text.isEmpty
          ? null
          : _searchController.text;
    });
    await _loadJobseekers(refresh: true);
  }

  Future<void> _updateUserStatus(int userId, String newStatus) async {
    try {
      await _apiService.updateUserStatus(userId, newStatus);
      AppScaffoldFeedback.show(
        context,
        message: 'User status updated to $newStatus',
        type: ResponseType.success,
      );
      await _loadJobseekers();
    } catch (e) {
      AppScaffoldFeedback.show(
        context,
        message: 'Failed to update status: $e',
        type: ResponseType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Jobseekers Management'), elevation: 0),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.tick_circle),
                  onPressed: _searchJobseekers,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onSubmitted: (_) => _searchJobseekers(),
            ),
          ),

          // Stats Summary
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_totalItems Jobseekers',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_totalPages > 1)
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Jobseekers List
          Expanded(
            child: _isLoading
                ? const SafeArea(child: ShimmerList())
                : _error != null
                ? _buildErrorView()
                : _jobseekers.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: () => _loadJobseekers(refresh: true),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _jobseekers.length,
                      itemBuilder: (context, index) {
                        return _buildJobseekerCard(_jobseekers[index]);
                      },
                    ),
                  ),
          ),

          // Pagination Controls
          if (_totalPages > 1) _buildPaginationControls(),
        ],
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
          Text('Failed to load jobseekers'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => _loadJobseekers(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.profile_2user, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            'No jobseekers found',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildJobseekerCard(AdminUserModel jobseeker) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and name
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: jobseeker.profileImageUrl != null
                      ? CachedNetworkImageProvider(jobseeker.profileImageUrl!)
                      : null,
                  child: jobseeker.profileImageUrl == null
                      ? Icon(
                          Iconsax.profile_tick,
                          size: 24.sp,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobseeker.name ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        jobseeker.email,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(jobseeker.status),
              ],
            ),
            SizedBox(height: 12.h),

            // Details
            Row(
              children: [
                if (jobseeker.location != null) ...[
                  Icon(Iconsax.location, size: 16.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    jobseeker.location!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  SizedBox(width: 12.w),
                ],
                if (jobseeker.experience != null) ...[
                  Icon(Iconsax.briefcase, size: 16.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    '${jobseeker.experience} years',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),

            // Skills (if available)
            if (jobseeker.skills != null && jobseeker.skills!.isNotEmpty) ...[
              Wrap(
                spacing: 4.w,
                runSpacing: 4.h,
                children: jobseeker.skills!.take(3).map((skill) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (jobseeker.skills!.length > 3)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    '+${jobseeker.skills!.length - 3} more skills',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                  ),
                ),
            ],
            SizedBox(height: 12.h),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showJobseekerDetails(jobseeker),
                  icon: Icon(
                    Iconsax.eye,
                    size: 16.sp,
                    color: context.theme.colorScheme.onSurface,
                  ),
                  label: Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Iconsax.more, size: 20.sp),
                  onSelected: (value) => _handleAction(value, jobseeker),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'activate',
                      child: Text(
                        jobseeker.status == 'active'
                            ? 'Already Active'
                            : 'Activate',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'deactivate',
                      child: Text(
                        jobseeker.status == 'inactive'
                            ? 'Already Inactive'
                            : 'Deactivate',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'suspend',
                      child: Text(
                        jobseeker.status == 'suspended'
                            ? 'Already Suspended'
                            : 'Suspend',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        break;
      case 'inactive':
        color = AppColors.textMuted;
        break;
      case 'suspended':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textMuted;
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

  Widget _buildPaginationControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.dividerDark
                : AppColors.divider,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadJobseekers();
                  }
                : null,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Previous'),
          ),
          Text(
            '$_currentPage / $_totalPages',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          ElevatedButton.icon(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadJobseekers();
                  }
                : null,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showJobseekerDetails(AdminUserModel jobseeker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (context, scrollController) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Jobseeker Details",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Iconsax.close_square),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  // Header with profile picture
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: jobseeker.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                jobseeker.profileImageUrl!,
                              )
                            : null,
                        child: jobseeker.profileImageUrl == null
                            ? Icon(
                                Iconsax.profile_2user,
                                size: 40.sp,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jobseeker.name ?? 'N/A',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (jobseeker.location != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                jobseeker.location!,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Personal Information Section
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow('Name', jobseeker.name ?? 'N/A'),
                  _buildDetailRow('Email', jobseeker.email),
                  if (jobseeker.phone != null)
                    _buildDetailRow('Phone', jobseeker.phone!),
                  if (jobseeker.location != null)
                    _buildDetailRow('Location', jobseeker.location!),
                  if (jobseeker.dateOfBirth != null)
                    _buildDetailRow(
                      'Date of Birth',
                      DateFormat('dd MMM yyyy').format(jobseeker.dateOfBirth!),
                    ),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Professional Information Section
                  Text(
                    'Professional Information',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (jobseeker.experience != null)
                    _buildDetailRow(
                      'Experience',
                      '${jobseeker.experience} years',
                    ),
                  if (jobseeker.qualification != null)
                    _buildDetailRow('Qualification', jobseeker.qualification!),
                  if (jobseeker.bio != null)
                    _buildDetailRowWithFullText('Bio', jobseeker.bio!),
                  if (jobseeker.skills != null &&
                      jobseeker.skills!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      'Skills',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: jobseeker.skills!.map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Resume Section
                  Text(
                    'Resume',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (jobseeker.resumeUrl != null)
                    _buildDetailRowWithAction(
                      'Resume File',
                      jobseeker.resumeFilename ?? 'Uploaded',
                      actionText: 'View',
                      onTap: () {
                        // TODO: Open resume URL or download
                        print('View Resume: ${jobseeker.resumeUrl}');
                      },
                    )
                  else
                    _buildDetailRow('Resume File', 'Not Uploaded'),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Account Status Section
                  Text(
                    'Account Status',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    'Status',
                    jobseeker.status.toUpperCase(),
                    valueColor: jobseeker.status == 'active'
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  _buildDetailRow(
                    'Email Verified',
                    jobseeker.emailVerified ? 'Verified' : 'Not Verified',
                    valueColor: jobseeker.emailVerified
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Account Details Section
                  Text(
                    'Account Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    'Joined At',
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(jobseeker.createdAt),
                  ),
                  _buildDetailRow(
                    'Last Updated',
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(jobseeker.updatedAt),
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
            width: 120.w,
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
        children: [
          SizedBox(
            width: 120.w,
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
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(actionText)),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithFullText(String label, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
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
              text,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, AdminUserModel jobseeker) {
    switch (action) {
      case 'activate':
        if (jobseeker.status != 'active') {
          _showStatusUpdateDialog(jobseeker, 'active');
        }
        break;
      case 'deactivate':
        if (jobseeker.status != 'inactive') {
          _showStatusUpdateDialog(jobseeker, 'inactive');
        }
        break;
      case 'suspend':
        if (jobseeker.status != 'suspended') {
          _showStatusUpdateDialog(jobseeker, 'suspended');
        }
        break;
    }
  }

  void _showStatusUpdateDialog(AdminUserModel jobseeker, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status'),
        content: Text(
          'Are you sure you want to ${newStatus.toLowerCase()} ${jobseeker.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUserStatus(jobseeker.id, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
