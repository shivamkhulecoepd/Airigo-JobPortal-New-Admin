import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/core/providers/saved_jobs_provider.dart';
import 'package:airigo_jobportal/screens/authentication/auth_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_dashboard_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_applications_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_profile_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/search_jobs_screen.dart';
import 'package:airigo_jobportal/widgets/common_nav_bar.dart';
import 'package:airigo_jobportal/models/jobseeker_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobseekerMainScreen extends ConsumerStatefulWidget {
  const JobseekerMainScreen({super.key});

  @override
  ConsumerState<JobseekerMainScreen> createState() =>
      _JobseekerMainScreenState();
}

class _JobseekerMainScreenState extends ConsumerState<JobseekerMainScreen> {
  int _currentIndex = 0;
  bool _savedJobsInitialized = false;

  final List<Widget> _jobseekerScreens = [
    const JobseekerDashboardScreen(),
    SearchJobsScreen(),
    const JobseekerApplicationsScreen(),
    const JobseekerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(authStateProvider)
        .when(
          data: (user) {
            if (user == null) {
              _redirectToLogin(context, 'jobseeker');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (user is! JobseekerModel) {
              _redirectToLogin(context, 'jobseeker');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Initialize saved jobs once after login
            if (!_savedJobsInitialized) {
              _savedJobsInitialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(savedJobsProvider.notifier).refresh();
                ref.read(savedJobsFullProvider.notifier).fetchFromApi();
              });
            }

            return Scaffold(
              body: IndexedStack(
                index: _currentIndex,
                children: _jobseekerScreens,
              ),
              bottomNavigationBar: CommonNavBar(
                role: "jobseeker",
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) {
            _redirectToLogin(context, 'jobseeker');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
  }

  void _redirectToLogin(BuildContext context, String type) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AuthScreen(userType: type, authType: 'login'),
        ),
      );
    });
  }
}
