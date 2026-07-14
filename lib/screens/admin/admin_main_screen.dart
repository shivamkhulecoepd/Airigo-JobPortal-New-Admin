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
    // ApplicationsManagementScreen(),
    IssuesManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ref.watch(authStateProvider).when(
      data: (user) {
        if (user == null) {
          _redirectToLogin(context);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Verify user is admin
        if (user.role != 'admin') {
          _redirectToLogin(context);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _adminScreens,
          ),
          bottomNavigationBar: AdminBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        _redirectToLogin(context);
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _redirectToLogin(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthScreen(userType: 'admin', authType: 'login'),
        ),
      );
    });
  }
}
