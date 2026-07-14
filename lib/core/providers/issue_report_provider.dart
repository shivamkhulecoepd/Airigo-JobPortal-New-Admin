import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api/issue_report_service.dart';
import '../service_locator.dart';

// Provider for the IssueReportService
final issueReportServiceProvider = Provider<IssueReportService>((ref) {
  return getIt<IssueReportService>();
});

// Future provider to submit issue report
final submitIssueReportProvider = FutureProvider.autoDispose.family<bool, Map<String, dynamic>>(
  (ref, params) async {
    final issueReportService = ref.watch(issueReportServiceProvider);
    
    try {
      final result = await issueReportService.createIssueReport(
        type: params['type'] ?? 'issue',
        title: params['title'] ?? '',
        description: params['description'] ?? '',
      );

      return result['success'] ?? false;
    } catch (e) {
      return false;
    }
  },
);