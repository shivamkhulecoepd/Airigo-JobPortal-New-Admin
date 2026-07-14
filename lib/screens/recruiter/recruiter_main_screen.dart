import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/screens/authentication/auth_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/applicants_list_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/job_post_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/manage_postings_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_dashboard_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_profile_screen.dart';
import 'package:airigo_jobportal/widgets/common_nav_bar.dart';
import 'package:airigo_jobportal/models/recruiter_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecruiterMainScreen extends ConsumerStatefulWidget {
  final int? index;
  const RecruiterMainScreen({super.key, this.index = 0});

  @override
  ConsumerState<RecruiterMainScreen> createState() =>
      _RecruiterMainScreenState();
}

class _RecruiterMainScreenState extends ConsumerState<RecruiterMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      _currentIndex = widget.index!;
    }
  }

  final List<Widget> _recruiterScreens = [
    const RecruiterDashboardScreen(),
    // RecruiterJobsScreen(),
    const ManagePostingsScreen(),
    const JobPostScreen(isBackButton: false),
    const ApplicantsListScreen(isBackButton: false),
    const RecruiterProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(authStateProvider)
        .when(
          data: (user) {
            if (user == null) {
              _redirectToLogin(context, 'recruiter');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (user is! RecruiterModel) {
              _redirectToLogin(context, 'recruiter');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              body: IndexedStack(
                index: _currentIndex,
                children: _recruiterScreens,
              ),
              bottomNavigationBar: CommonNavBar(
                role: "recruiter",
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
            _redirectToLogin(context, 'recruiter');
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
