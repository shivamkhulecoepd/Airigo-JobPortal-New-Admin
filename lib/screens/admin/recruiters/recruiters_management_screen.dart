import 'dart:developer';

import 'package:airigo_jobportal/models/admin/admin_user_model.dart';
import 'package:airigo_jobportal/services/admin/admin_api_service.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/utils/theme.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recruiter approved'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadRecruiters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recruiter rejected'),
            backgroundColor: Colors.red,
          ),
        );
        await _loadRecruiters();
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
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
          ? const Center(child: CircularProgressIndicator())
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
                        ? Image.network(
                            recruiter.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppTheme.primaryBrand,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Iconsax.building,
                              size: 28.sp,
                              color: AppTheme.primaryBrand,
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
                        recruiter.companyName ?? 'N/A',
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
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve'),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => _rejectRecruiter(recruiter.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
    log('Showing recruiter details:- ${recruiter.toJson()}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with company/recruiter name
                  Text(
                    "Recruiter Details",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.h),
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
                              ? Image.network(
                                  recruiter.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: AppTheme.primaryBrand,
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    Iconsax.building,
                                    size: 32.sp,
                                    color: AppTheme.primaryBrand,
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
                  SizedBox(height: 24.h),
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
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildDetailRow(
                    'Approval Status',
                    (recruiter.approvalStatus ?? 'pending').toUpperCase(),
                    valueColor: recruiter.approvalStatus == 'approved'
                        ? Colors.green
                        : recruiter.approvalStatus == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                  ),
                  _buildDetailRow(
                    'Email Verified',
                    recruiter.emailVerified ? 'Verified' : 'Not Verified',
                    valueColor: recruiter.emailVerified
                        ? Colors.green
                        : Colors.red,
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
                  Icon(
                    Iconsax.image,
                    size: 24.sp,
                    color: AppTheme.primaryBrand,
                  ),
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
                  placeholder: (context, url) => Container(
                    height: 300.h,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
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
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(imageUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: Icon(Iconsax.export_1),
                    label: Text('Open in Browser'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Iconsax.close_circle),
                    label: Text('Close'),
                  ),
                ],
              ),
            ),
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
