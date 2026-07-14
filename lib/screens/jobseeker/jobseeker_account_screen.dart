import 'dart:developer';

import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import 'package:airigo_jobportal/core/providers/jobseeker_profile_provider.dart';
import 'package:airigo_jobportal/models/jobseeker_model.dart';
import 'package:airigo_jobportal/models/profile_model.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

// ─── Profile Screen ───────────────────────────────────────────────────────────
class JobseekerAccountScreen extends ConsumerStatefulWidget {
  const JobseekerAccountScreen({super.key});

  @override
  ConsumerState<JobseekerAccountScreen> createState() =>
      _JobseekerProfileScreenState();
}

class _JobseekerProfileScreenState
    extends ConsumerState<JobseekerAccountScreen> {
  bool _isUploadingImage = false;
  bool _isUploadingResume = false;
  List<String>? _localSkills; // Cache skills locally for instant UI update

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

    // Watch both providers to get profile data
    final jobseeker = ref.watch(currentJobseekerProvider);
    final profileState = ref.watch(jobseekerProfileProvider);

    if (jobseeker == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Use profile provider data if available (after updates), otherwise use auth provider
    // This ensures real-time updates without manual refresh
    JobseekerModel dataToUse;
    if (profileState.profile != null) {
      dataToUse = profileState.profile!;
    } else {
      dataToUse = jobseeker;
    }

    // Use local skills if available (for instant UI update), otherwise use from provider
    final profile = _mapModelToProfile(dataToUse);

    // Update local skills cache if they exist
    if (_localSkills != null) {
      profile.skills = _localSkills!;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh auth state to get latest profile data from API
          await ref.read(authStateProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 170.h,
              floating: true,
              pinned: false,
              // surfaceTintColor: theme.colorScheme.surface,
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20.sp,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              title: Text(
                'Account Info',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              actions: [_navIconBtn(Iconsax.setting_2, _openSettings, theme)],
              actionsPadding: EdgeInsets.only(right: 16.w),
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const Spacer(), _buildProfileHero(theme, profile)],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  _buildPersonalInfoSection(theme, profile),
                  SizedBox(height: 8.h),
                  _buildBioSection(theme, profile),
                  SizedBox(height: 8.h),
                  _buildSkillsSection(theme, profile),
                  SizedBox(height: 8.h),
                  _buildExperienceSlider(theme, profile),
                  SizedBox(height: 8.h),
                  _buildResumeSection(theme, profile),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Personal Info (Scaffold Bottom Sheet) ────────────────────────────
  void _editPersonalInfo(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    final nameController = TextEditingController(text: profile.name);
    final phoneController = TextEditingController(text: profile.phone);
    final qualificationController = TextEditingController(
      text: profile.qualification ?? '',
    );
    DateTime? selectedDob = profile.dateOfBirth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Personal Info',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20.sp),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: qualificationController,
                decoration: InputDecoration(
                  labelText: 'Qualification',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDob ?? DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setModalState(() {
                      selectedDob = picked;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.calendar, color: AppColors.primary),
                      SizedBox(width: 12.w),
                      Text(
                        selectedDob != null
                            ? '${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}'
                            : 'Select Date of Birth',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: selectedDob != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);

                    // Show loading
                    AppScaffoldFeedback.show(
                      context,
                      message: 'Updating...',
                      type: ResponseType.warning,
                    );

                    // Update personal details
                    await ref
                        .read(jobseekerProfileProvider.notifier)
                        .updatePersonalDetails(
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                        );

                    // Update education (qualification + DOB)
                    await ref
                        .read(jobseekerProfileProvider.notifier)
                        .updateEducation(
                          qualification: qualificationController.text.trim(),
                          dateOfBirth: selectedDob
                              ?.toIso8601String()
                              .split('T')
                              .first,
                        );

                    // Refresh data
                    await ref.read(authStateProvider.notifier).refresh();

                    if (mounted) {
                      AppScaffoldFeedback.show(
                        context,
                        message: 'Personal info updated!',
                        type: ResponseType.success,
                      );
                    }
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
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

  // ── Profile Image Upload ───────────────────────────────────────────────────
  Future<void> _updateProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploadingImage = true);

        final success = await ref
            .read(jobseekerProfileProvider.notifier)
            .updateProfileImage(image.path);

        setState(() => _isUploadingImage = false);

        if (mounted) {
          AppScaffoldFeedback.show(
            context,
            message: success
                ? 'Profile image updated!'
                : 'Failed to update image',
            type: success ? ResponseType.success : ResponseType.error,
          );

          // Refresh auth state
          if (success) {
            await ref.read(authStateProvider.notifier).refresh();
          }
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        AppScaffoldFeedback.show(
          context,
          message: 'Error: $e',
          type: ResponseType.error,
        );
      }
    }
  }

  // ── Resume Upload ──────────────────────────────────────────────────────────
  Future<void> _updateResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        setState(() => _isUploadingResume = true);

        final success = await ref
            .read(jobseekerProfileProvider.notifier)
            .updateResume(filePath);

        setState(() => _isUploadingResume = false);

        if (mounted) {
          AppScaffoldFeedback.show(
            context,
            message: success
                ? 'Resume uploaded: $fileName'
                : 'Failed to upload resume',
            type: success ? ResponseType.success : ResponseType.error,
          );

          if (success) {
            await ref.read(authStateProvider.notifier).refresh();
          }
        }
      }
    } catch (e) {
      setState(() => _isUploadingResume = false);
      if (mounted) {
        AppScaffoldFeedback.show(
          context,
          message: 'Error: $e',
          type: ResponseType.error,
        );
      }
    }
  }

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
                  borderRadius: BorderRadius.circular(10),
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
                icon: Iconsax.notification_bing,
                label: 'Notification Preferences',
                theme: theme,
                onTap: () => Navigator.pop(context),
              ),
              _modernSettingsTile(
                icon: Iconsax.lock,
                label: 'Privacy & Security',
                theme: theme,
                onTap: () => Navigator.pop(context),
              ),
              _modernSettingsTile(
                icon: Iconsax.logout,
                label: 'Log Out',
                theme: theme,
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/onboarding', (route) => false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modernSettingsTile({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
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
                    color: isDestructive
                        ? Colors.red
                        : theme.colorScheme.primary,
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
                          : (isDark
                                ? Colors.white
                                : theme.colorScheme.onSurface),
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
                          Iconsax.location,
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
    return SizedBox(
      width: 92.w,
      height: 92.w,
      child: ClipOval(
        child: Image.network(
          profile.avatarUrl,
          width: 74.w,
          height: 74.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: 37.r,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Iconsax.user,
              size: 36.sp,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bio Section ────────────────────────────────────────────────────────────
  Widget _buildBioSection(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => _editBio(theme, profile),
            child: Text(
              profile.bio,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Personal Info Section ───────────────────────────────────────────────────
  Widget _buildPersonalInfoSection(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      decoration: BoxDecoration(
        // color: theme.cardColor,
        color: theme.scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              _editBtn(() => _editPersonalInfo(theme, profile), theme),
            ],
          ),
          // SizedBox(height: 8.h),
          _buildInfoRow(
            theme,
            icon: Iconsax.message,
            label: 'Email',
            value: profile.email ?? 'Not provided',
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            theme,
            icon: Iconsax.call,
            label: 'Phone',
            value: profile.phone ?? 'Not provided',
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            theme,
            icon: Iconsax.cake,
            label: 'Date of Birth',
            value: profile.dateOfBirth != null
                ? '${profile.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}'
                : 'Not provided',
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            theme,
            icon: Iconsax.teacher,
            label: 'Qualification',
            value: profile.qualification ?? 'Not provided',
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            theme,
            icon: Iconsax.clock,
            label: 'Member Since',
            value: profile.createdAt != null
                ? _formatMemberSince(profile.createdAt!)
                : 'Unknown',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: theme.colorScheme.primary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMemberSince(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _editBio(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    final controller = TextEditingController(text: profile.bio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Bio',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                hintText: 'Write about yourself...',
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);

                  // Save to database
                  final success = await ref
                      .read(jobseekerProfileProvider.notifier)
                      .updateBio(bio: controller.text.trim());

                  if (mounted) {
                    AppScaffoldFeedback.show(
                      context,
                      message: success
                          ? 'Bio updated!'
                          : 'Failed to update bio',
                      type: success ? ResponseType.success : ResponseType.error,
                    );

                    // Refresh data
                    if (success) {
                      await ref.read(authStateProvider.notifier).refresh();
                    }
                  }
                },
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skills Section ─────────────────────────────────────────────────────────
  Widget _buildSkillsSection(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ...profile.skills.map((s) => _skillChip(s, theme, profile)),
              _addSkillChip(theme, profile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String label, ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: () => _removeSkill(label, theme, profile),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2D3748)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: isDark ? Colors.white24 : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _addSkillChip(ThemeData theme, ProfileData profile) {
    return GestureDetector(
      onTap: () => _addSkill(theme, profile),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: theme.colorScheme.primary,
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.add_circle,
              size: 15.sp,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 4.w),
            Text(
              'Add Skill',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSkill(ThemeData theme, ProfileData profile) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          'Add Skill',
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Flutter, Dart',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                Navigator.pop(ctx);

                // Add to local cache IMMEDIATELY for instant UI update
                final currentSkills =
                    _localSkills ?? List<String>.from(profile.skills);
                if (!currentSkills.contains(v)) {
                  currentSkills.add(v);
                  setState(() {
                    _localSkills = currentSkills;
                  });
                }

                // Show loading message
                if (mounted) {
                  AppScaffoldFeedback.show(
                    context,
                    message: 'Adding skill...',
                    type: ResponseType.success,
                  );
                }

                // Save to database in background
                final success = await ref
                    .read(jobseekerProfileProvider.notifier)
                    .updateSkills(skills: currentSkills);

                if (mounted) {
                  if (success) {
                    log('Skill added successfully!');
                    AppScaffoldFeedback.show(
                      context,
                      message: 'Skill added successfully!',
                      type: ResponseType.success,
                    );

                    // Refresh data from API to ensure consistency
                    await ref.read(authStateProvider.notifier).refresh();

                    // Update local cache with the fresh data from provider
                    // This ensures subsequent adds build on the correct base
                    if (mounted) {
                      final updatedJobseeker = ref.read(
                        currentJobseekerProvider,
                      );
                      if (updatedJobseeker != null) {
                        setState(() {
                          _localSkills = List<String>.from(
                            updatedJobseeker.skills,
                          );
                        });
                      } else {
                        // Fallback: keep currentSkills if refresh didn't work
                        setState(() {
                          _localSkills = currentSkills;
                        });
                      }
                    }
                  } else {
                    // Remove from local cache if save failed
                    setState(() {
                      _localSkills?.remove(v);
                    });
                    log('Failed to add skill');
                    AppScaffoldFeedback.show(
                      context,
                      message: 'Failed to add skill. Please try again.',
                      type: ResponseType.error,
                    );
                  }
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _removeSkill(String skill, ThemeData theme, ProfileData profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text('Remove "$skill"?', style: TextStyle(fontSize: 15.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              // Remove from local cache IMMEDIATELY for instant feedback
              final currentSkills =
                  _localSkills ?? List<String>.from(profile.skills);
              final wasRemoved = currentSkills.remove(skill);

              if (wasRemoved) {
                setState(() {
                  _localSkills = currentSkills;
                });
              }

              // Show removing message
              if (mounted) {
                AppScaffoldFeedback.show(
                  context,
                  message: 'Removing skill...',
                  type: ResponseType.warning,
                );
              }

              // Save to database in background
              final success = await ref
                  .read(jobseekerProfileProvider.notifier)
                  .updateSkills(skills: currentSkills);

              if (mounted) {
                if (success) {
                  AppScaffoldFeedback.show(
                    context,
                    message: 'Skill removed successfully!',
                    type: ResponseType.success,
                  );

                  // Refresh data from API to ensure consistency
                  await ref.read(authStateProvider.notifier).refresh();

                  // Update local cache with the fresh data from provider
                  // This ensures subsequent removes build on the correct base
                  if (mounted) {
                    final updatedJobseeker = ref.read(currentJobseekerProvider);
                    if (updatedJobseeker != null) {
                      setState(() {
                        _localSkills = List<String>.from(
                          updatedJobseeker.skills,
                        );
                      });
                    } else {
                      // Fallback: keep currentSkills if refresh didn't work
                      setState(() {
                        _localSkills = currentSkills;
                      });
                    }
                  }
                } else {
                  // Add back to local cache if save failed
                  if (wasRemoved && !currentSkills.contains(skill)) {
                    setState(() {
                      _localSkills?.add(skill);
                    });
                  }

                  AppScaffoldFeedback.show(
                    context,
                    message: 'Failed to remove skill. Please try again.',
                    type: ResponseType.error,
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Experience Slider ──────────────────────────────────────────────────────
  Widget _buildExperienceSlider(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    String label = '';
    if (profile.experienceYears < 3) {
      label = 'Junior';
    } else if (profile.experienceYears < 7) {
      label = 'Mid-Level';
    } else if (profile.experienceYears < 12) {
      label = 'Mid-Senior';
    } else {
      label = 'Expert';
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experience Level',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
              trackHeight: 6.h,
            ),
            child: Slider(
              value: profile.experienceYears,
              min: 0,
              max: 15,
              divisions: 15,
              onChanged: (v) async {
                // Update UI immediately
                setState(() => profile.experienceYears = v);

                // Save to database
                await ref
                    .read(jobseekerProfileProvider.notifier)
                    .updateExperience(experience: v.toInt());

                // Refresh data
                await ref.read(authStateProvider.notifier).refresh();
              },
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Junior (0)',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '$label (${profile.experienceYears.toInt()}y)',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Expert (15+)',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Resume Section ─────────────────────────────────────────────────────────
  Widget _buildResumeSection(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 14.h),
          if (profile.resumeFileName != null)
            _buildUploadedResumeRow(theme, profile)
          else
            _buildResumeUploadBox(theme, profile),
        ],
      ),
    );
  }

  Widget _buildResumeUploadBox(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _pickResume(profile),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 32.h),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2D3748)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.white24
                : theme.colorScheme.outlineVariant,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.cloud_add,
                color: theme.colorScheme.primary,
                size: 26.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Upload your latest CV',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'PDF, DOCX up to 10MB',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark
                    ? Colors.white70
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _pickResume(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                elevation: 3,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'Browse Files',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedResumeRow(ThemeData theme, ProfileData profile) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A5F)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Iconsax.document, color: theme.colorScheme.primary, size: 24.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.resumeFileName!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Uploaded just now',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark
                        ? Colors.white70
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Iconsax.trash, color: Colors.red, size: 20.sp),
            onPressed: () => setState(() => profile.resumeFileName = null),
          ),
        ],
      ),
    );
  }

  void _pickResume(ProfileData profile) {
    // Simulate file pick with dummy names
    final files = [
      'Alex_Johnson_Resume_2024.pdf',
      'Product_Designer_CV.pdf',
      'Alex_CV_Latest.docx',
    ];
    final picked = files[math.Random().nextInt(files.length)];
    setState(() => profile.resumeFileName = picked);
    final theme = Theme.of(context);

    AppScaffoldFeedback.show(
      context,
      message: 'Resume "$picked" uploaded!',
      type: ResponseType.info,
    );
  }
}

// ── Reusable: Edit Button ──────────────────────────────────────────────────────
Widget _editBtn(VoidCallback onTap, ThemeData theme) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        Icon(Iconsax.edit, size: 14.sp, color: theme.colorScheme.primary),
        SizedBox(width: 4.w),
        Text(
          'Edit',
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

// ── Custom Circular Progress Painter ─────────────────────────────────────────
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _CircularProgressPainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 5.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFDBEAFE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fgPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) => old.progress != progress;
}
