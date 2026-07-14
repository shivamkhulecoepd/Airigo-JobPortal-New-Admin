import 'dart:developer';

import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/screens/authentication/choose_role_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_dashboard_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_main_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_dashboard_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_main_screen.dart';
import 'package:airigo_jobportal/services/api/auth_service.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/storage/pending_job_service.dart';

enum FieldType { email, password, name, phone }

class AuthScreen extends ConsumerStatefulWidget {
  final String userType;
  final String authType;
  const AuthScreen({required this.userType, required this.authType, super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  bool _rememberMe = false;

  bool _isLoading = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!emailRegex.hasMatch(value)) {
      return "Enter valid email";
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Name is required";
    }

    if (value.length < 3) {
      return "Name must be at least 3 characters";
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number required";
    }

    if (value.length != 10) {
      return "Enter valid 10 digit phone";
    }

    return null;
  }

  void _loginUser() async {
    if (_isLoading) return;

    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String email = _loginEmailController.text.trim();
    final String password = _loginPasswordController.text.trim();

    try {
      final authNotifier = ref.read(authStateProvider.notifier);

      if (widget.userType == 'jobseeker') {
        await authNotifier.loginAsJobseeker(email, password);
      } else if (widget.userType == 'recruiter') {
        await authNotifier.loginAsRecruiter(email, password);
      } else if (widget.userType == 'admin') {
        await authNotifier.loginAsAdmin(email, password);
      }

      final authState = ref.read(authStateProvider);
      if (authState.hasValue && authState.value != null) {
        AppScaffoldFeedback.show(
          context,
          message: "Login Successful",
          type: ResponseType.success,
        );

        // Navigate based on user type using common helper
        if (widget.userType == 'recruiter') {
          final hasPending = await PendingJobService().hasPendingJob();
          if (hasPending) {
            await _postPendingJobAndNavigate();
          } else {
            _navigateToDashboard();
          }
        } else if (widget.userType == 'admin') {
          Navigator.of(context).pop();
        } else {
          _navigateToDashboard();
        }
      } else {
        AppScaffoldFeedback.show(
          context,
          message: authState.error?.toString() ?? "Login failed",
          type: ResponseType.error,
        );
      }
    } catch (e) {
      AppScaffoldFeedback.show(
        context,
        message: "Login failed: ${e.toString()}",
        type: ResponseType.error,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _registerUser() async {
    if (_isLoading) return;

    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String name = _registerNameController.text.trim();
    final String email = _registerEmailController.text.trim();
    final String password = _registerPasswordController.text.trim();
    final String phone = _registerPhoneController.text.trim();

    try {
      final authService = AuthService();
      final result = await authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        userType: widget.userType,
      );

      if (result['success']) {
        // Update Riverpod state so the main screens know the user is logged in
        await ref.read(authStateProvider.notifier).refresh();

        AppScaffoldFeedback.show(
          context,
          message: "Registration Successful",
          type: ResponseType.success,
        );

        // Check if there's a pending job to post (for recruiters)
        if (widget.userType == 'recruiter') {
          final hasPendingJob = await PendingJobService().hasPendingJob();
          if (hasPendingJob) {
            // New automated flow with progress dialog
            await _postPendingJobAndNavigate();
          } else {
            _navigateToDashboard();
          }
        } else {
          _navigateToDashboard();
        }
      } else {
        // log("Registration failed: ${result['message']}");
        log("Registration failed: ${result.toString()}");
        AppScaffoldFeedback.show(
          context,
          message: result['message'] ?? "Registration failed",
          // message: result['errors']['password'] ?? "Registration failed",
          type: ResponseType.error,
        );
      }
    } catch (e) {
      AppScaffoldFeedback.show(
        context,
        message: "Registration failed: ${e.toString()}",
        type: ResponseType.error,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final int initialIndex = widget.authType.toLowerCase() == "register"
        ? 1
        : 0;

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Stack(
        children: [
          // Background gradient circles
          Positioned(
            top: -100.h,
            right: -100.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150.h,
            left: -80.w,
            child: Container(
              width: 200.w,
              height: 200.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            spacing: 16.h,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: EdgeInsetsGeometry.only(
                  top: 10.h,
                  left: 16.h,
                  right: 16.h,
                ),
                child: Column(
                  spacing: 5.h,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              HapticFeedback.heavyImpact();
                              // Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChooseRoleScreen(),
                                ),
                              );
                            },
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        margin: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Header text
                    Text(
                      'Go ahead and set up\nyour account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Sign in-up to enjoy the best managing experience',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // White card with tabs
              _buildScrollableAuthContainer(theme: theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableAuthContainer({required ThemeData theme}) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22.r),
            topRight: Radius.circular(22.r),
          ),
        ),

        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),

          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),

              /// TAB BAR
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 18.w),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? theme.dividerColor.withValues(alpha: 0.07)
                        : Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: _isLoading ? (_) {} : null,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: const Color(0xFF999999),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: "Login"),
                      Tab(text: "Register"),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            ];
          },

          /// TAB CONTENT
          body: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildLoginTab(theme),
              ),

              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildRegisterTab(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _loginFormKey,
        child: Column(
          spacing: 16.h,
          children: [
            // Email field
            _buildTextField(
              controller: _loginEmailController,
              hintText: "Email ID",
              icon: Icons.email_outlined,
              fieldType: FieldType.email,
            ),

            // Password field
            _buildTextField(
              controller: _loginPasswordController,
              hintText: "Password",
              icon: Icons.lock_outline,
              fieldType: FieldType.password,
              isLoginField: true,
            ),

            // Remember me & Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 8.w,
                  children: [
                    SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        side: BorderSide(
                          color: const Color(0xFFCCCCCC),
                          width: 1.5.w,
                        ),
                        activeColor: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Remember me',
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.vibrate();
                  },
                  child: Text(
                    'Forget Password?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Login button
            _buildPrimaryButton('Login', theme, _loginUser),
            const SizedBox(),
            // Or login with
            Row(
              spacing: 16.w,
              children: [
                Expanded(
                  child: Divider(
                    color: const Color(0xFFE0E0E0),
                    thickness: 1.h,
                  ),
                ),
                Text(
                  'Or login with',
                  style: TextStyle(
                    color: const Color(0xFF999999),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: const Color(0xFFE0E0E0),
                    thickness: 1.h,
                  ),
                ),
              ],
            ),

            // Social buttons
            Row(
              spacing: 12.w,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildSocialButton('Google', isGoogle: true)),
                Expanded(child: _buildSocialButton('Apple', isApple: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _registerFormKey,
        child: Column(
          spacing: 16.h,
          children: [
            // Full Name field
            _buildTextField(
              controller: _registerNameController,
              hintText: "Full Name",
              icon: Icons.person_outline,
              fieldType: FieldType.name,
            ),

            // Email field
            _buildTextField(
              controller: _registerEmailController,
              hintText: "Email ID",
              icon: Icons.email_outlined,
              fieldType: FieldType.email,
            ),

            // Phone No. field
            _buildTextField(
              controller: _registerPhoneController,
              hintText: "Phone",
              icon: Icons.phone_outlined,
              fieldType: FieldType.phone,
            ),

            // Password field
            _buildTextField(
              controller: _registerPasswordController,
              hintText: "Password",
              icon: Icons.lock_outline,
              fieldType: FieldType.password,
            ),

            SizedBox(height: 12.h),

            // Register button
            _buildPrimaryButton('Register', theme, _registerUser),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required FieldType fieldType,
    bool isLoginField = false,
  }) {
    final bool isPassword = fieldType == FieldType.password;

    final bool isVisible = isLoginField
        ? _loginPasswordVisible
        : _registerPasswordVisible;

    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !isVisible : false,
      keyboardType: fieldType == FieldType.phone
          ? TextInputType.phone
          : fieldType == FieldType.email
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hintText,

        prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 20.sp),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    if (isLoginField) {
                      _loginPasswordVisible = !_loginPasswordVisible;
                    } else {
                      _registerPasswordVisible = !_registerPasswordVisible;
                    }
                  });
                },
              )
            : null,

        filled: true,
        // fillColor: const Color(0xFFF8F8F8),
        fillColor: context.isDark
            ? context.theme.scaffoldBackgroundColor
            : Colors.white,

        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(
            color: context.isDark
                ? context.theme.dividerColor.withValues(alpha: 0.2)
                : context.theme.dividerColor.withValues(alpha: 0.08),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(
            color: context.isDark
                ? Colors.white.withOpacity(0.2)
                : context.theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: BorderSide(
            color: context.isDark
                ? Colors.white.withOpacity(0.5)
                : Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.r),
          borderSide: const BorderSide(color: Colors.red),
        ),

        errorStyle: TextStyle(fontSize: 12.sp, height: 1.3),
      ),

      validator: (value) {
        switch (fieldType) {
          case FieldType.email:
            return _validateEmail(value);

          case FieldType.password:
            return _validatePassword(value);

          case FieldType.phone:
            return _validatePhone(value);

          case FieldType.name:
            return _validateName(value);
        }
      },
    );
  }

  Widget _buildPrimaryButton(String text, ThemeData theme, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 6,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text, {
    bool isGoogle = false,
    bool isApple = false,
  }) {
    return InkWell(
      onTap: _isLoading
          ? null
          : () => AppScaffoldFeedback.show(
              context,
              message: isApple
                  ? 'Continue with apple tapped.'
                  : 'Continue with google tapped.',
              type: ResponseType.info,
            ),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: context.theme.dividerColor.withValues(
              alpha: context.isDark ? 0.2 : 0.08,
            ),
            width: 1.w,
          ),
        ),
        child: Row(
          spacing: 8.w,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGoogle)
              Image.asset(
                'assets/icons/Google-Icon.png',
                width: 20.w,
                height: 20.w,
              )
            else if (isApple)
              Icon(Icons.apple, size: 24.sp),
            Text(
              text,
              style: TextStyle(
                color: context.isDark
                    ? Color.fromARGB(255, 188, 188, 188)
                    : Color(0xFF666666),
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDashboard() {
    if (widget.userType == 'jobseeker') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const JobseekerMainScreen()),
        (route) => false,
      );
    } else if (widget.userType == 'recruiter') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RecruiterMainScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _postPendingJobAndNavigate() async {
    final pendingJobData = await PendingJobService().getPendingJob();
    if (pendingJobData == null) {
      _navigateToDashboard();
      return;
    }

    // Show horizontal loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Publishing Job',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Please wait while we post your job automatically...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                ),
                SizedBox(height: 24.h),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Small delay to ensure auth state is propagated
      await Future.delayed(const Duration(milliseconds: 1000));

      final jobsNotifier = ref.read(jobsStateProvider.notifier);

      await jobsNotifier.createJob(
        companyName: pendingJobData['companyName'] as String,
        companyUrl: pendingJobData['companyUrl'] as String?,
        designation: pendingJobData['designation'] as String,
        ctc: pendingJobData['ctc'] as String,
        location: pendingJobData['location'] as String,
        category: pendingJobData['category'] as String,
        description: pendingJobData['description'] as String,
        requirements: (pendingJobData['requirements'] as List?)?.cast<String>(),
        skillsRequired: (pendingJobData['skillsRequired'] as List?)
            ?.cast<String>(),
        perksAndBenefits: (pendingJobData['perksAndBenefits'] as List?)
            ?.cast<String>(),
        experienceRequired: pendingJobData['experienceRequired'] as String,
        jobType: pendingJobData['jobType'] as String,
        isActive: pendingJobData['isActive'] as bool? ?? true,
        isUrgentHiring: pendingJobData['isUrgentHiring'] as bool? ?? false,
        companyLogoPath: pendingJobData['companyLogoPath'] as String?,
      );

      await PendingJobService().clearPendingJob();

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        AppScaffoldFeedback.show(
          context,
          message: 'Job posted successfully!',
          type: ResponseType.success,
        );
        // Small delay for the snackbar to be readable
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToDashboard();
      }
    } catch (e) {
      log('Error posting pending job: $e');
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        AppScaffoldFeedback.show(
          context,
          message: 'Failed to post job: $e',
          type: ResponseType.error,
        );
        _navigateToDashboard(); // Navigate anyway
      }
    }
  }
}
