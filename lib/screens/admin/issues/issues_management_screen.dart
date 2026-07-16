import 'dart:developer';

import 'package:airigo_jobportal/models/admin/admin_issue_model.dart';
import 'package:airigo_jobportal/services/admin/admin_api_service.dart';
import 'package:airigo_jobportal/utils/theme.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading issues: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue updated'),
            backgroundColor: Colors.green,
          ),
        );
        _loadIssues();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
          ? const Center(child: CircularProgressIndicator())
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
        backgroundColor: AppTheme.primaryBrand,
        child: const Icon(Icons.refresh),
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
                Icon(
                  issue.type == 'report' ? Iconsax.flag : Iconsax.warning_2,
                  color: AppTheme.primaryBrand,
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
                  color: AppTheme.primaryBrand.withOpacity(0.1),
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
                  ),
                if (issue.status == 'in_progress')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(issue.id, 'resolved'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                if (issue.status == 'resolved')
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(issue.id, 'in_progress'),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reopen'),
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
        color = Colors.orange;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'resolved':
        color = Colors.green;
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
