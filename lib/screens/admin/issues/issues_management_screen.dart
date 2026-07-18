import 'dart:developer';

import 'package:airigo_jobportal/models/admin/admin_issue_model.dart';
import 'package:airigo_jobportal/services/admin/admin_api_service.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:airigo_jobportal/widgets/shimmer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class IssuesManagementScreen extends StatefulWidget {
  const IssuesManagementScreen({super.key});

  @override
  State<IssuesManagementScreen> createState() => _IssuesManagementScreenState();
}

class _IssuesManagementScreenState extends State<IssuesManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminApiService _apiService = AdminApiService();
  late TabController _tabController;
  Map<String, List<AdminIssueModel>> _issuesByStatus = {
    'pending': [],
    'in_progress': [],
    'resolved': [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getIssues();

      // Handle different response formats
      List<dynamic> issuesData;
      if (response['data'] is List) {
        issuesData = response['data'] as List<dynamic>;
      } else {
        // If no data field or it's not a list, use empty list
        issuesData = [];
      }

      final issues = issuesData
          .map((json) => AdminIssueModel.fromJson(json))
          .toList();

      _issuesByStatus = {
        'pending': issues.where((i) => i.status == 'pending').toList(),
        'in_progress': issues.where((i) => i.status == 'in_progress').toList(),
        'resolved': issues.where((i) => i.status == 'resolved').toList(),
      };

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Error loading issues: $e');
        AppScaffoldFeedback.show(
          context,
          message: 'Error loading issues: $e',
          type: ResponseType.error,
        );
      }
    }
  }

  Future<void> _updateStatus(int issueId, String status) async {
    final responseController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Issue Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Admin Response (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, {'response': responseController.text}),
            child: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _apiService.updateIssueStatus(
          issueId,
          status,
          adminResponse: result['response']?.isNotEmpty == true
              ? result['response']
              : null,
        );
        AppScaffoldFeedback.show(
          context,
          message: 'Issue updated',
          type: ResponseType.success,
        );
        _loadIssues();
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
        title: const Text('Issues & Reports'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onSurface,
          tabs: [
            Tab(text: 'Pending (${_issuesByStatus['pending']?.length ?? 0})'),
            Tab(
              text:
                  'In Progress (${_issuesByStatus['in_progress']?.length ?? 0})',
            ),
            Tab(text: 'Resolved (${_issuesByStatus['resolved']?.length ?? 0})'),
          ],
        ),
      ),
      body: _isLoading
          ? const SafeArea(child: ShimmerList())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIssuesList('pending'),
                _buildIssuesList('in_progress'),
                _buildIssuesList('resolved'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_issues_refresh',
        onPressed: _loadIssues,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildIssuesList(String status) {
    final issues = _issuesByStatus[status] ?? [];

    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.flag, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text('No $status issues'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIssues,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: issues.length,
        itemBuilder: (context, index) {
          return _buildIssueCard(issues[index]);
        },
      ),
    );
  }

  Widget _buildIssueCard(AdminIssueModel issue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
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
            Row(
              children: [
                Icon(
                  issue.type == 'report' ? Iconsax.flag : Iconsax.warning_2,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    issue.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(issue.status),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              issue.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Text(
                  'By: ${issue.userName ?? issue.userType}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(width: 12.w),
                Text(
                  DateFormat('dd MMM yyyy').format(issue.createdAt),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
            if (issue.adminResponse != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Response:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      issue.adminResponse!,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (issue.status == 'pending')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(issue.id, 'in_progress'),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start Working'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (issue.status == 'in_progress')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(issue.id, 'resolved'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (issue.status == 'resolved')
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(issue.id, 'in_progress'),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reopen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
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
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        break;
      case 'in_progress':
        color = AppColors.secondary;
        break;
      case 'resolved':
        color = AppColors.success;
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
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
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
