import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/models/user_model.dart';
import 'package:airigo_jobportal/screens/admin/admin_dashboard_screen.dart';
import 'package:airigo_jobportal/screens/admin/jobseekers/jobseekers_management_screen.dart';
import 'package:airigo_jobportal/screens/admin/recruiters/recruiters_management_screen.dart';
import 'package:airigo_jobportal/screens/admin/jobs/jobs_management_screen.dart';
import 'package:airigo_jobportal/screens/admin/applications/applications_management_screen.dart';
import 'package:airigo_jobportal/screens/admin/issues/issues_management_screen.dart';
import 'package:airigo_jobportal/screens/authentication/auth_screen.dart';
import 'package:airigo_jobportal/widgets/admin/admin_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _adminScreens = const [
    AdminDashboardScreen(),
    JobseekersManagementScreen(),
    RecruitersManagementScreen(),
    JobsManagementScreen(),
    IssuesManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    // Show a loading spinner only if we don't have a user yet and are currently loading.
    // This prevents the entire screen from flashing a spinner during background refreshes.
    if (user == null && authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If we finished loading but there's no user, or the user is not an admin, redirect.
    if (user == null || user.role != 'admin') {
      _redirectToLogin(context);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _adminScreens[_currentIndex],
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _redirectToLogin(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const AuthScreen(userType: 'admin', authType: 'login'),
        ),
      );
    });
  }
}
