import 'package:airigo_jobportal/services/admin/admin_api_service.dart';
import 'package:airigo_jobportal/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class ApplicationsManagementScreen extends StatefulWidget {
  const ApplicationsManagementScreen({super.key});

  @override
  State<ApplicationsManagementScreen> createState() => _ApplicationsManagementScreenState();
}

class _ApplicationsManagementScreenState extends State<ApplicationsManagementScreen> {
  final AdminApiService _apiService = AdminApiService();
  bool _isLoading = true;
  List<dynamic> _applications = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getApplications(page: _currentPage, limit: 20);
      setState(() {
        _applications = response['data'] ?? [];
        _currentPage = response['pagination']?['page'] ?? 1;
        _totalPages = response['pagination']?['pages'] ?? 1;
        _totalItems = response['pagination']?['total'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateStatus(int appId, String status) async {
    // Admin cannot change application status - only recruiters can
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Only recruiters can update application status'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      appBar: AppBar(
        title: const Text('Applications Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadApplications),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('No applications found'))
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text('$_totalItems Total Applications',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadApplications,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: _applications.length,
                          itemBuilder: (context, index) {
                            final app = _applications[index];
                            return _buildApplicationCard(app);
                          },
                        ),
                      ),
                    ),
                    if (_totalPages > 1) _buildPagination(),
                  ],
                ),
    );
  }

  Widget _buildApplicationCard(dynamic application) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBrand.withOpacity(0.1),
                  child: Icon(Iconsax.profile, color: AppTheme.primaryBrand),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application['jobseeker_name'] ?? 'Jobseeker',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Text(application['job_title'] ?? 'Job',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),
                ),
                _buildStatusBadge(application['status']),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showApplicationDetails(application),
                  icon: Icon(Iconsax.eye, size: 16.sp),
                  label: const Text('View Details'),
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
      case 'shortlisted':
        color = Colors.blue;
        break;
      case 'accepted':
        color = Colors.green;
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
      child: Text(status.toUpperCase(),
          style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadApplications();
                  }
                : null,
            child: const Text('Previous'),
          ),
          Text('$_currentPage / $_totalPages'),
          ElevatedButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadApplications();
                  }
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showApplicationDetails(dynamic application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: 24.h),
                  Text(
                    'Application Details',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  _buildDetailRow('Jobseeker', application['jobseeker_name'] ?? 'N/A'),
                  _buildDetailRow('Job Title', application['job_title'] ?? 'N/A'),
                  _buildDetailRow('Company', application['company_name'] ?? 'N/A'),
                  _buildDetailRow('Status', (application['status'] ?? 'pending').toUpperCase()),
                  if (application['applied_date'] != null)
                    _buildDetailRow('Applied Date', application['applied_date']),
                  if (application['cover_letter'] != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      'Cover Letter',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      application['cover_letter'],
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20.sp, color: Colors.orange),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Only the respective recruiter can update application status',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
