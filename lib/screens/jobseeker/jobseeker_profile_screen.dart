import 'dart:developer';
import 'dart:math' as math;

import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/core/providers/theme_provider.dart';
import 'package:airigo_jobportal/models/jobseeker_model.dart';
import 'package:airigo_jobportal/models/profile_model.dart';
import 'package:airigo_jobportal/screens/common/about_app_screen.dart';
import 'package:airigo_jobportal/screens/authentication/change_password_screen.dart';
import 'package:airigo_jobportal/screens/common/help_feedback_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_account_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_edit_profile_screen.dart';
import 'package:airigo_jobportal/screens/jobseeker/jobseeker_savedjobs_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class JobseekerProfileScreen extends ConsumerStatefulWidget {
  const JobseekerProfileScreen({super.key});

  @override
  ConsumerState<JobseekerProfileScreen> createState() =>
      _JobseekerProfileScreenState();
}

class _JobseekerProfileScreenState
    extends ConsumerState<JobseekerProfileScreen> {
  // Map JobseekerModel to ProfileData for UI compatibility
  ProfileData _mapModelToProfile(JobseekerModel model) {
    return ProfileData(
      name: model.name,
      title: model.qualification ?? 'Jobseeker',
      location: model.location,
      avatarUrl:
          model.avatarUrl ??
          'https://ui-avatars.com/api/?name=${model.name}&background=6366f1&color=fff',
      level: 1, // Default or calculated
      completionPercent: model.profileCompletion,
      bio: model.bio ?? 'No bio provided.',
      skills: model.skills,
      experienceYears: model.experienceYears.toDouble(),
      email: model.email,
      phone: model.phone,
      dateOfBirth: model.dateOfBirth != null
          ? DateTime.parse(model.dateOfBirth!)
          : null,
      qualification: model.qualification,
      createdAt: model.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final mq = MediaQuery.of(context);

    final jobseeker = ref.watch(currentJobseekerProvider);

    if (jobseeker == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _mapModelToProfile(jobseeker);

    bool isDarkMode = isDark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh auth state to get latest profile data from API
          await ref.read(authStateProvider.notifier).refresh();

          // Also try to fetch profile directly from API to ensure fresh data
          final authState = ref.read(authStateProvider);
          if (authState.hasValue && authState.value != null) {
            final user = authState.value;
            final userType = user.runtimeType.toString().toLowerCase();
            if (userType.contains('jobseeker')) {
              // Re-fetch jobseeker profile from API
              final result = await ref.read(authStateProvider.notifier).build();
              // The refresh() call above already handles this
            }
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 170.h,
              floating: true,
              pinned: false,
              surfaceTintColor: theme.scaffoldBackgroundColor,
              backgroundColor: theme.scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero-animated company logo
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: mq.padding.top,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildProfileHero(theme, profile),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  children: [
                    // Edit Profile Button
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const JobseekerEditProfileScreen(),
                            ),
                          );
                        },
                        child: Ink(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.white.withValues(alpha: 0.05),
                                      Colors.white.withValues(alpha: 0.05),
                                    ]
                                  : [
                                      theme.primaryColor.withValues(alpha: 0.6),
                                      theme.primaryColor.withValues(alpha: 0.5),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: const Icon(
                                  Iconsax.edit_2,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              const Expanded(
                                child: Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _modernSettingsTile(
                      icon: Iconsax.user,
                      label: 'Account Info',
                      theme: theme,
                      screen: const JobseekerAccountScreen(),
                    ),
                    _modernSettingsTile(
                      icon: Iconsax.bookmark,
                      label: 'Saved Jobs',
                      theme: theme,
                      // screen: JobseekerSavedJobsScreen(),
                      screen: const SavedJobsScreen(),
                    ),
                    _themeToggleTile(
                      theme: theme,
                      isDarkMode: isDark,
                      onToggle: (value) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setTheme(value ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                    _modernSettingsTile(
                      icon: Iconsax.lock,
                      label: 'Change Password',
                      theme: theme,
                      screen: const ChangePasswordScreen(),
                    ),
                    _modernSettingsTile(
                      icon: Iconsax.message_question,
                      label: 'Help & Feedback',
                      theme: theme,
                      screen: const HelpFeedbackScreen(),
                    ),
                    _modernSettingsTile(
                      icon: Iconsax.mobile,
                      label: 'About App',
                      theme: theme,
                      screen: const AboutAppScreen(),
                    ),
                    _modernSettingsTile(
                      icon: Iconsax.logout,
                      label: 'Log Out',
                      theme: theme,
                      isDestructive: true,
                      screen: null,
                      onTap: () async {
                        _showLogoutDialog(context, isDark);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Functions
  void _openSettings() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Drag Handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),

              SizedBox(height: 16.h),

              // 🔹 Title
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 20.h),

              // 🔹 Tiles
              _modernSettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notification Preferences',
                theme: theme,
              ),
              _modernSettingsTile(
                icon: Icons.lock_outline,
                label: 'Privacy & Security',
                theme: theme,
              ),
              _modernSettingsTile(
                icon: Icons.logout,
                label: 'Log Out',
                theme: theme,
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.logout,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 16),

                /// Title
                const Text(
                  "Logout?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                /// Subtitle
                Text(
                  "Are you sure you want to logout from your account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 24),

                /// Buttons
                Row(
                  children: [
                    /// Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// Logout
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/onboarding',
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modernSettingsTile({
    required IconData icon,
    required String label,
    required ThemeData theme,
    bool isDestructive = false,
    Widget? screen,
    Function()? onTap,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => screen != null
            ? Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              )
            : onTap != null
            ? onTap()
            : null,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              // 🔹 Icon Container
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.12)
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red : theme.colorScheme.primary,
                  size: 20.sp,
                ),
              ),

              SizedBox(width: 14.w),

              // 🔹 Label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Colors.red
                        : (theme.colorScheme.onSurface),
                  ),
                ),
              ),

              // 🔹 Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeToggleTile({
    required ThemeData theme,
    required bool isDarkMode,
    required ValueChanged<bool> onToggle,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        // onTap: () => onToggle(!isDarkMode),
        onTap: () {
          log("Tapped: ${!isDarkMode}");
          onToggle(!isDarkMode);
        },
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              // 🔹 Icon Container
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isDarkMode ? Iconsax.moon : Iconsax.sun_1,
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
              ),

              SizedBox(width: 14.w),

              // 🔹 Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isDarkMode ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔥 Custom Switch (Premium)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44.w,
                height: 26.h,
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: isDarkMode
                      ? theme.colorScheme.primary
                      : Colors.grey.shade400,
                ),
                child: Align(
                  alignment: isDarkMode
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable: Nav Icon Button ─────────────────────────────────────────────────
  Widget _navIconBtn(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme, {
    Color? color,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Icon(
        icon,
        size: 22.sp,
        color: color ?? (theme.colorScheme.onSurface),
      ),
    );
  }

  // ── Profile Hero ───────────────────────────────────────────────────────────
  Widget _buildProfileHero(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _circularProgressAvatar(theme, profile),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      profile.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark
                            ? Colors.white70
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14.sp,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          profile.location,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // SizedBox(height: 20.h),
          // _buildCompletionCard(theme),
        ],
      ),
    );
  }

  Widget _circularProgressAvatar(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => profile.avatarUrl != null
          ? _showIdCardFullScreen(profile.avatarUrl)
          : null,
      child: Container(
        width: 92.w,
        height: 92.w,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2.w),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            profile.avatarUrl,
            width: 90.w,
            height: 90.w,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              radius: 37.r,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 36.sp,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showIdCardFullScreen(String imageUrl) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Full screen image
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ShimmerImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  errorWidget: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onSurface,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
