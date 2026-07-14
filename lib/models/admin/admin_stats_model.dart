class AdminStatsModel {
  final int totalUsers;
  final int totalJobseekers;
  final int totalRecruiters;
  final int activeUsers;
  final int inactiveUsers;
  final int suspendedUsers;
  final int totalJobs;
  final int activeJobs;
  final int inactiveJobs;
  final int pendingJobs;
  final int approvedJobs;
  final int rejectedJobs;
  final int totalApplications;
  final int pendingApplications;
  final int shortlistedApplications;
  final int acceptedApplications;
  final int rejectedApplications;
  final int totalRecruiterAccounts;
  final int pendingRecruiters;
  final int approvedRecruiters;
  final int rejectedRecruiters;
  final int totalIssues;
  final int pendingIssues;
  final int inProgressIssues;
  final int resolvedIssues;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalJobseekers,
    required this.totalRecruiters,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.suspendedUsers,
    required this.totalJobs,
    required this.activeJobs,
    required this.inactiveJobs,
    required this.pendingJobs,
    required this.approvedJobs,
    required this.rejectedJobs,
    required this.totalApplications,
    required this.pendingApplications,
    required this.shortlistedApplications,
    required this.acceptedApplications,
    required this.rejectedApplications,
    required this.totalRecruiterAccounts,
    required this.pendingRecruiters,
    required this.approvedRecruiters,
    required this.rejectedRecruiters,
    required this.totalIssues,
    required this.pendingIssues,
    required this.inProgressIssues,
    required this.resolvedIssues,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    // Handle different response formats
    // Try nested structure first: stats.users.total
    Map<String, dynamic> stats;
    if (json['stats'] != null) {
      stats = json['stats'];
    } else {
      // If no stats wrapper, use the json directly
      stats = json;
    }
    
    final users = stats['users'] ?? {};
    final jobs = stats['jobs'] ?? {};
    final applications = stats['applications'] ?? {};
    final recruiters = stats['recruiters'] ?? {};
    final issues = stats['issues_reports'] ?? stats['issues'] ?? {};

    // Handle flat structure (if backend returns flat data)
    return AdminStatsModel(
      totalUsers: users['total'] ?? stats['total_users'] ?? 0,
      totalJobseekers: users['jobseekers'] ?? stats['total_jobseekers'] ?? 0,
      totalRecruiters: users['recruiters'] ?? stats['total_recruiters'] ?? 0,
      activeUsers: users['active'] ?? stats['active_users'] ?? 0,
      inactiveUsers: users['inactive'] ?? stats['inactive_users'] ?? 0,
      suspendedUsers: users['suspended'] ?? stats['suspended_users'] ?? 0,
      totalJobs: jobs['total'] ?? stats['total_jobs'] ?? 0,
      activeJobs: jobs['active'] ?? stats['active_jobs'] ?? 0,
      inactiveJobs: jobs['inactive'] ?? stats['inactive_jobs'] ?? 0,
      pendingJobs: jobs['pending_approval'] ?? stats['pending_jobs'] ?? 0,
      approvedJobs: jobs['approved'] ?? stats['approved_jobs'] ?? 0,
      rejectedJobs: jobs['rejected'] ?? stats['rejected_jobs'] ?? 0,
      totalApplications: applications['total'] ?? stats['total_applications'] ?? 0,
      pendingApplications: applications['pending'] ?? stats['pending_applications'] ?? 0,
      shortlistedApplications: applications['shortlisted'] ?? stats['shortlisted_applications'] ?? 0,
      acceptedApplications: applications['accepted'] ?? stats['accepted_applications'] ?? 0,
      rejectedApplications: applications['rejected'] ?? stats['rejected_applications'] ?? 0,
      totalRecruiterAccounts: recruiters['total'] ?? stats['total_recruiter_accounts'] ?? 0,
      pendingRecruiters: recruiters['pending_approval'] ?? stats['pending_recruiters'] ?? 0,
      approvedRecruiters: recruiters['approved'] ?? stats['approved_recruiters'] ?? 0,
      rejectedRecruiters: recruiters['rejected'] ?? stats['rejected_recruiters'] ?? 0,
      totalIssues: issues['total'] ?? stats['total_issues'] ?? 0,
      pendingIssues: issues['pending'] ?? stats['pending_issues'] ?? 0,
      inProgressIssues: issues['in_progress'] ?? stats['in_progress_issues'] ?? 0,
      resolvedIssues: issues['resolved'] ?? stats['resolved_issues'] ?? 0,
    );
  }
}
