import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/screens/authentication/auth_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/applicants_list_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/job_post_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/manage_postings_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_dashboard_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_profile_screen.dart';
import 'package:airigo_jobportal/widgets/common_nav_bar.dart';
import 'package:airigo_jobportal/models/recruiter_model.dart';
import 'package:airigo_jobportal/widgets/shimmer_card.dart';
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
    const ManagePostingsScreen(),
    const JobPostScreen(isBackButton: false),
    const ApplicantsListScreen(isBackButton: false),
    const RecruiterProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    // Show a loading spinner only if we don't have a user yet and are currently loading.
    // This prevents the entire screen from flashing a spinner during background refreshes.
    if (user == null && authState.isLoading) {
      return const Scaffold(body: SafeArea(child: ShimmerList()));
    }

    // If we finished loading but there's no user, or the user is not an admin, redirect.
    if (user == null || user.role != 'recruiter') {
      _redirectToLogin(context, 'recruiter');
      return const Scaffold(body: SafeArea(child: ShimmerList()));
    }

    return Scaffold(
      body: _recruiterScreens[_currentIndex],
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
