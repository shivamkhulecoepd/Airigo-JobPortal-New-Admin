import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PendingJobService {
  static final PendingJobService _instance = PendingJobService._internal();
  factory PendingJobService() => _instance;
  PendingJobService._internal();

  static const String _pendingJobKey = 'pending_job_data';
  static const String _hasPendingJobKey = 'has_pending_job';

  /// Check if there's a pending job to be posted
  Future<bool> hasPendingJob() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasPendingJobKey) ?? false;
  }

  /// Save job data temporarily before registration
  Future<void> savePendingJob(Map<String, dynamic> jobData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingJobKey, jsonEncode(jobData));
    await prefs.setBool(_hasPendingJobKey, true);
    print('PendingJobService: Job data saved temporarily');
  }

  /// Get pending job data
  Future<Map<String, dynamic>?> getPendingJob() async {
    final prefs = await SharedPreferences.getInstance();
    final jobDataString = prefs.getString(_pendingJobKey);
    if (jobDataString != null) {
      try {
        return jsonDecode(jobDataString) as Map<String, dynamic>;
      } catch (e) {
        print('PendingJobService: Error parsing pending job data: $e');
        return null;
      }
    }
    return null;
  }

  /// Clear pending job data after successful posting
  Future<void> clearPendingJob() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingJobKey);
    await prefs.setBool(_hasPendingJobKey, false);
    print('PendingJobService: Pending job data cleared');
  }
}
