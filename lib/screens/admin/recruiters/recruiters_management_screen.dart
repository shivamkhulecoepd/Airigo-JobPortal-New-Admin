import 'dart:developer';

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
import 'package:url_launcher/url_launcher.dart';

class RecruitersManagementScreen extends StatefulWidget {
  const RecruitersManagementScreen({super.key});

  @override
  State<RecruitersManagementScreen> createState() =>
      _RecruitersManagementScreenState();
}

class _RecruitersManagementScreenState extends State<RecruitersManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  late TabController _tabController;

  Map<String, List<AdminUserModel>> _recruitersByStatus = {
    'pending': [],
    'approved': [],
    'rejected': [],
  };
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecruiters();
  }

  Future<void> _loadRecruiters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getRecruiters(
        page: _currentPage,
        limit: 50,
      );

      // Handle different response formats
      List<dynamic> data;
      if (response['data'] is List) {
        data = response['data'] as List<dynamic>;
      } else if (response['recruiters'] is List) {
        data = response['recruiters'] as List<dynamic>;
      } else {
        data = [];
      }

      final recruiters = data
          .map((json) => AdminUserModel.fromJson(json))
          .toList();

      // Group by approval status
      _recruitersByStatus = {
        'pending': recruiters
            .where((r) => r.approvalStatus == 'pending')
            .toList(),
        'approved': recruiters
            .where((r) => r.approvalStatus == 'approved')
            .toList(),
        'rejected': recruiters
            .where((r) => r.approvalStatus == 'rejected')
            .toList(),
      };

      final pagination = response['pagination'] ?? response['meta'] ?? {};
      setState(() {
        _currentPage = pagination['page'] ?? 1;
        _totalPages = pagination['pages'] ?? pagination['last_page'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveRecruiter(int userId) async {
    try {
      await _apiService.approveRecruiter(userId);
      AppScaffoldFeedback.show(
        context,
        message: 'Recruiter approved',
        type: ResponseType.success,
      );
      await _loadRecruiters();
    } catch (e) {
      AppScaffoldFeedback.show(
        context,
        message: 'Failed: $e',
        type: ResponseType.error,
      );
    }
  }

  Future<void> _rejectRecruiter(int userId) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Recruiter'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _apiService.rejectRecruiter(userId, result);
        AppScaffoldFeedback.show(
          context,
          message: 'Recruiter rejected',
          type: ResponseType.success,
        );
        await _loadRecruiters();
      } catch (e) {
        AppScaffoldFeedback.show(
          context,
          message: 'Failed: $e',
          type: ResponseType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Recruiters Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onSurface,
          tabs: [
            Tab(
              text: 'Pending (${_recruitersByStatus['pending']?.length ?? 0})',
            ),
            Tab(
              text:
                  'Approved (${_recruitersByStatus['approved']?.length ?? 0})',
            ),
            Tab(
              text:
                  'Rejected (${_recruitersByStatus['rejected']?.length ?? 0})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const SafeArea(child: ShimmerList())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecruiterList('pending'),
                _buildRecruiterList('approved'),
                _buildRecruiterList('rejected'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_recruiters_refresh',
        onPressed: () => _loadRecruiters(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
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
          Text('Failed to load recruiters'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadRecruiters,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruiterList(String status) {
    final recruiters = _recruitersByStatus[status] ?? [];

    if (recruiters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.building, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text('No $status recruiters'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecruiters,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: recruiters.length,
        itemBuilder: (context, index) {
          return _buildRecruiterCard(recruiters[index]);
        },
      ),
    );
  }

  Widget _buildRecruiterCard(AdminUserModel recruiter) {
    log('Recruiter data while rendering:- ${recruiter.toJson()}');
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
            Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: recruiter.profileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: recruiter.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 28.sp,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Iconsax.building,
                              size: 28.sp,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recruiter.name ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        recruiter.email,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            if (recruiter.designation != null) ...[
              Row(
                children: [
                  Icon(Iconsax.user, size: 16.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    'Designation: ${recruiter.designation}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],

            if (recruiter.location != null) ...[
              Row(
                children: [
                  Icon(Iconsax.location, size: 16.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    recruiter.location!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),
            ],

            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRecruiterDetails(recruiter),
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
                if (recruiter.approvalStatus == 'pending') ...[
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => _approveRecruiter(recruiter.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => _rejectRecruiter(recruiter.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reject'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecruiterDetails(AdminUserModel recruiter) {
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
                  // Header with company/recruiter name
                  Row(
                    children: [
                      Text(
                        "Recruiter Details",
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
                  Row(
                    children: [
                      Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withValues(alpha: 0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35.r),
                          child: recruiter.profileImageUrl != null
                              ? CachedNetworkImage(
                            imageUrl: recruiter.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 28.sp,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Iconsax.building,
                              size: 28.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recruiter.companyName ?? 'N/A',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (recruiter.designation != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                recruiter.designation!,
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
                  SizedBox(height: 20.h),
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
                  _buildDetailRow(
                    'Company Name',
                    recruiter.companyName ?? 'N/A',
                  ),
                  if (recruiter.designation != null)
                    _buildDetailRow('Designation', recruiter.designation!),
                  if (recruiter.recruiterName != null)
                    _buildDetailRow('Recruiter Name', recruiter.recruiterName!),
                  if (recruiter.companyWebsite != null)
                    _buildDetailRowWithAction(
                      'Company Website',
                      recruiter.companyWebsite!,
                      actionText: 'Visit',
                      onTap: () async {
                        final url = Uri.parse(recruiter.companyWebsite!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Contact Information Section
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow('Email', recruiter.email),
                  if (recruiter.phone != null)
                    _buildDetailRow('Phone', recruiter.phone!),
                  if (recruiter.location != null)
                    _buildDetailRow('Location', recruiter.location!),
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
                    recruiter.status.toUpperCase(),
                    valueColor: recruiter.status == 'active'
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  _buildDetailRow(
                    'Approval Status',
                    (recruiter.approvalStatus ?? 'pending').toUpperCase(),
                    valueColor: recruiter.approvalStatus == 'approved'
                        ? AppColors.success
                        : recruiter.approvalStatus == 'rejected'
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                  _buildDetailRow(
                    'Email Verified',
                    recruiter.emailVerified ? 'Verified' : 'Not Verified',
                    valueColor: recruiter.emailVerified
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Documents Section
                  Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (recruiter.idCardUrl != null)
                    _buildDetailRowWithAction(
                      'ID Card',
                      'Uploaded',
                      actionText: 'View',
                      onTap: () => _showIdCardImage(recruiter.idCardUrl!),
                    )
                  else
                    _buildDetailRow('ID Card', 'Not Uploaded'),
                  SizedBox(height: 16.h),
                  Divider(),
                  SizedBox(height: 16.h),

                  // Timestamps Section
                  Text(
                    'Account Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildDetailRow(
                    'Created At',
                    DateFormat(
                      'MMM dd, yyyy hh:mm a',
                    ).format(recruiter.createdAt),
                  ),
                  _buildDetailRow(
                    'Last Updated',
                    DateFormat(
                      'MMM dd, yyyy hh:mm a',
                    ).format(recruiter.updatedAt),
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
              ": $value",
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
        // crossAxisAlignment: CrossAxisAlignment.start,
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
              ": $value",
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionText,
              style: TextStyle(color: context.theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showIdCardImage(String imageUrl) {
    Navigator.pop(context); // Close the details modal first

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Icon(Iconsax.image, size: 20.sp, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Text(
                    'ID Card',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Iconsax.close_circle),
                  ),
                ],
              ),
            ),
            Divider(),
            // Image
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => SizedBox(
                    height: 300.h,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => SizedBox(
                    height: 300.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 48.sp,
                            color: Colors.red,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Divider(),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () async {
                    final url = Uri.parse(imageUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text('Open in Browser'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
