// recruiter_profile_screen.dart
// Dependencies: flutter_screenutil: ^5.9.0

import 'dart:developer';
import 'dart:isolate';

import 'package:airigo_jobportal/services/api/auth_service.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../models/recruiter_model.dart';

class RecruiterProfileScreen extends ConsumerStatefulWidget {
  const RecruiterProfileScreen({super.key});
  @override
  ConsumerState<RecruiterProfileScreen> createState() =>
      _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState
    extends ConsumerState<RecruiterProfileScreen> {
  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _shareProfile(RecruiterModel? recruiter) async {
    if (recruiter == null) return;

    // Build comprehensive profile text
    final StringBuffer profileText = StringBuffer();

    // Header
    profileText.writeln('👤 RECRUITER PROFILE');
    profileText.writeln('=' * 40);
    profileText.writeln();

    // Personal Info
    profileText.writeln('📋 Personal Information');
    profileText.writeln('• Name: ${recruiter.recruiterName ?? recruiter.name}');
    profileText.writeln('• Designation: ${recruiter.designation}');
    profileText.writeln('• Company: ${recruiter.company}');
    profileText.writeln(
      '• Status: ${recruiter.approvalStatus == 'approved' ? '✅ Verified' : '❌ Not Verified'}',
    );
    profileText.writeln();

    // Contact Details
    profileText.writeln('📞 Contact Details');
    profileText.writeln('• Email: ${recruiter.email}');
    profileText.writeln('• Phone: ${recruiter.phone}');
    profileText.writeln('• Location: ${recruiter.location}');
    profileText.writeln();

    // Company Info
    if (recruiter.companyWebsite != null &&
        recruiter.companyWebsite!.isNotEmpty) {
      profileText.writeln('🌐 Company Website');
      profileText.writeln(recruiter.companyWebsite!);
      profileText.writeln();
    }

    // Footer with Play Store link
    profileText.writeln('=' * 40);
    profileText.writeln('📲 Download Airigo Job Portal App');
    profileText.writeln(
      'https://play.google.com/store/apps/details?id=com.aptitsolutions.airigo',
    );
    profileText.writeln();
    profileText.writeln('Shared via Airigo Job Portal');
    profileText.writeln('📅 ${DateTime.now().toString().split('.')[0]}');

    // Share via native system share sheet (WhatsApp, Messages, Gmail, etc.)
    try {
      final result = await Share.share(
        profileText.toString(),
        subject:
            'Recruiter Profile - ${recruiter.recruiterName ?? recruiter.name}',
      );

      // Log share result
      switch (result.status) {
        case ShareResultStatus.success:
          log('Profile shared successfully');
          AppScaffoldFeedback.show(
            context,
            message: 'Profile shared successfully',
            type: ResponseType.success,
          );
          break;
        case ShareResultStatus.dismissed:
          log('Share dialog dismissed');
          break;
        case ShareResultStatus.unavailable:
          AppScaffoldFeedback.show(
            context,
            message: 'Sharing not available on this device',
            type: ResponseType.error,
          );
          break;
      }
    } catch (e) {
      log('Error sharing profile: $e');
      AppScaffoldFeedback.show(
        context,
        message: 'Failed to share profile',
        type: ResponseType.error,
      );
    }
  }

  Future<void> _shareProfileAsImage(RecruiterModel? recruiter) async {
    if (recruiter == null) return;

    // Build concise profile text
    final StringBuffer profileText = StringBuffer();
    profileText.writeln('👤 ${recruiter.recruiterName ?? recruiter.name}');
    profileText.writeln(
      '💼 ${recruiter.designation ?? 'Recruiter'} at ${recruiter.company}',
    );
    profileText.writeln('📧 ${recruiter.email}');
    profileText.writeln('📱 ${recruiter.phone}');
    profileText.writeln('📍 ${recruiter.location}');
    if (recruiter.companyWebsite != null &&
        recruiter.companyWebsite!.isNotEmpty) {
      profileText.writeln('🌐 ${recruiter.companyWebsite}');
    }
    profileText.writeln();
    profileText.writeln(
      '📲 Download App: https://play.google.com/store/apps/details?id=com.aptitsolutions.airigo',
    );
    profileText.writeln();
    profileText.writeln('Shared via Airigo Job Portal');

    // Share via native system share sheet
    try {
      await Share.share(
        profileText.toString(),
        subject: 'Contact - ${recruiter.recruiterName ?? recruiter.name}',
      );
    } catch (e) {
      log('Error sharing profile: $e');
      AppScaffoldFeedback.show(
        context,
        message: 'Failed to share profile',
        type: ResponseType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final recruiter = authState.value as RecruiterModel?;

    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE8E5E0);
    final labelColor = isDark
        ? const Color(0xFF9A9A9A)
        : const Color(0xFF7A7570);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1714);
    final accentColor = theme.colorScheme.primary;
    final subtleFill = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFF3F1EE);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            // forceMaterialTransparency: true,
            elevation: 1,
            shadowColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

            automaticallyImplyLeading: false,

            title: Text(
              'Profile',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setTheme(isDark ? ThemeMode.light : ThemeMode.dark),
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    size: 18.sp,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
            actionsPadding: EdgeInsets.only(right: 10.w),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(authStateProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
              child: Column(
                children: [
                  _buildProfileHero(theme, isDark, recruiter, borderColor),
                  SizedBox(height: 14.h),
                  _buildCompanyInfoCard(theme, isDark, recruiter, borderColor),
                  SizedBox(height: 14.h),
                  _buildContactDetailsCard(
                    theme,
                    isDark,
                    recruiter,
                    borderColor,
                  ),
                  SizedBox(height: 14.h),
                  _buildIdCardSection(theme, isDark, recruiter, borderColor),
                  SizedBox(height: 14.h),
                  _buildAccountSecurityCard(
                    theme,
                    isDark,
                    recruiter,
                    borderColor,
                  ),
                  SizedBox(height: 14.h),
                  _buildLogoutButton(theme, isDark),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  //── Profile Hero───────────────────────────────────────────────────────────
  Widget _buildProfileHero(
    ThemeData theme,
    bool isDark,
    RecruiterModel? recruiter,
    Color borderColor,
  ) {
    final status = _getApprovalStatus(recruiter!.approvalStatus);
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: status['color'],
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(14.r),
                bottomLeft: Radius.circular(14.r),
              ),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              status['status']?.toUpperCase(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _card(
          borderColor: borderColor,
          child: Column(
            children: [
              // Avatar with camera button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => recruiter.avatarUrl != null
                        ? _showIdCardFullScreen(recruiter.avatarUrl!)
                        : null,
                    child: ShimmerImage(
                      imageUrl: recruiter.avatarUrl ?? '',
                      width: 100.w,
                      height: 100.w,
                      borderRadius: 14.r,
                      errorWidget: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 48.sp,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadImage(),
                      child: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 15.sp,
                          // color: theme.colorScheme.surface,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                recruiter.recruiterName ?? recruiter.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                recruiter.designation ?? 'Recruiter',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 14.sp,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    recruiter.company ?? 'Company',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editProfile(recruiter),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 2,
                        shadowColor: theme.colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                      ),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16.sp,
                        // color: theme.colorScheme.surface,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Edit Profile',
                        style: TextStyle(
                          // color: theme.colorScheme.surface,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showShareOptions(recruiter),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      icon: Icon(
                        Icons.share_outlined,
                        size: 16.sp,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Share Portfolio',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getApprovalStatus(String approvalStatus) {
    switch (approvalStatus) {
      case 'pending':
        return {'status': 'pending', 'color': Colors.amber};
      case 'approved':
        return {'status': 'approved', 'color': Colors.green};
      case 'rejected':
        return {'status': 'rejected', 'color': Colors.red};
      default:
        return {'status': 'pending', 'color': Colors.grey};
    }
  }

  // ── Company Info ───────────────────────────────────────────────────────────
  Widget _buildCompanyInfoCard(
    ThemeData theme,
    bool isDark,
    RecruiterModel? recruiter,
    Color borderColor,
  ) {
    return _card(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.business_center_outlined,
            'Company Info',
            isDark,
            theme,
            onTap: () => _editCompanyInfo(recruiter),
          ),
          SizedBox(height: 14.h),
          _infoTile(
            'ORGANIZATION',
            recruiter?.company ?? 'Not specified',
            theme,
            isDark,
          ),
          SizedBox(height: 8.h),
          _infoTile(
            'DESIGNATION',
            recruiter?.designation ?? 'Recruiter',
            theme,
            isDark,
          ),
          SizedBox(height: 8.h),
          _infoTileLink(
            'WEBSITE',
            recruiter?.companyWebsite ?? 'Not specified',
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.7,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTileLink(
    String label,
    String value,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.7,
            ),
          ),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () {
              log('Open on browser tapped: $value');
              HapticFeedback.mediumImpact();

              // Check if the value is a valid URL
              if (value == 'Not specified' || value.isEmpty) {
                AppScaffoldFeedback.show(
                  context,
                  message: 'No website URL specified',
                  type: ResponseType.error,
                );
                return;
              }

              try {
                final uri = Uri.parse(value);
                // Add https:// prefix if no scheme is present
                final finalUri = uri.scheme.isEmpty
                    ? Uri.parse('https://$value')
                    : uri;

                _launchInBrowser(finalUri);
              } catch (e) {
                log('Error parsing URL: $e');
                AppScaffoldFeedback.show(
                  context,
                  message: 'Invalid URL format',
                  type: ResponseType.error,
                );
              }
            },
            child: Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.secondary,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.open_in_new,
                  size: 14.sp,
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact Details ────────────────────────────────────────────────────────
  Widget _buildContactDetailsCard(
    ThemeData theme,
    bool isDark,
    RecruiterModel? recruiter,
    Color borderColor,
  ) {
    return _card(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.contact_mail_outlined,
            'Contact Details',
            isDark,
            theme,
            onTap: () => _editContact(recruiter),
          ),
          SizedBox(height: 10.h),
          _contactRow(
            Icons.mail_outline,
            recruiter?.email ?? 'Not specified',
            'Primary Work Email',
          ),
          _contactRow(
            Icons.phone_outlined,
            recruiter?.phone ?? 'Not specified',
            'Direct Office Line',
          ),
          _contactRow(
            Icons.location_on_outlined,
            recruiter?.location ?? 'Not specified',
            'Office Location',
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String value, String subtitle) {
    return InkWell(
      onTap: () => AppScaffoldFeedback.show(context, message: value),
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: AppColors.textMuted),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Account Security ───────────────────────────────────────────────────────
  Widget _buildAccountSecurityCard(
    ThemeData theme,
    bool isDark,
    RecruiterModel? recruiter,
    Color borderColor,
  ) {
    bool _twoFAEnabled = false; // This would typically come from user settings

    return _card(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.shield_outlined,
            'Account Security',
            isDark,
            theme,
          ),
          SizedBox(height: 14.h),
          _securityTile(
            Icons.key_outlined,
            'Change Password',
            trailing: Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: AppColors.textMuted,
            ),
            onTap: _changePassword,
          ),
          SizedBox(height: 8.h),
          _securityTile(
            Icons.phonelink_setup_outlined,
            'Two-Factor Auth',
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: _twoFAEnabled
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                _twoFAEnabled ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: _twoFAEnabled
                      ? AppColors.success
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ),
          // SizedBox(height: 8.h),
          // _securityTile(
          //   Icons.devices_outlined,
          //   'Active Sessions',
          //   trailing: Icon(
          //     Icons.chevron_right,
          //     size: 20.sp,
          //     color: AppColors.textMuted,
          //   ),
          //   onTap: _showActiveSessions,
          // ),
        ],
      ),
    );
  }

  Widget _securityTile(
    IconData icon,
    String label, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: AppColors.textMuted),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_outlined,
              size: 18.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: 8.w),
            Text(
              'Logout from RecruitHub',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showShareOptions(RecruiterModel? recruiter) {
    if (recruiter == null) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            Text(
              'Share Profile',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'Choose how you want to share this profile',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // Share via Native Share Sheet
            _shareOptionCard(
              icon: Icons.share_outlined,
              title: 'Share via Apps',
              subtitle: 'WhatsApp, Messages, Gmail, Telegram, etc.',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(ctx);
                _shareProfile(recruiter);
              },
            ),
            SizedBox(height: 12.h),

            // Quick Share Contact Info
            _shareOptionCard(
              icon: Icons.contact_mail_outlined,
              title: 'Share Contact Info',
              subtitle: 'Quick share essential contact details',
              color: Colors.green,
              onTap: () {
                Navigator.pop(ctx);
                _shareProfileAsImage(recruiter);
              },
            ),
            SizedBox(height: 12.h),

            // Copy to Clipboard
            _shareOptionCard(
              icon: Icons.copy_all_outlined,
              title: 'Copy to Clipboard',
              subtitle: 'Copy full profile text for pasting anywhere',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(ctx);
                _copyProfileToClipboard(recruiter);
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _shareOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _copyProfileToClipboard(RecruiterModel recruiter) async {
    final StringBuffer profileText = StringBuffer();

    profileText.writeln('👤 RECRUITER PROFILE');
    profileText.writeln('=' * 40);
    profileText.writeln();
    profileText.writeln('📋 Personal Information');
    profileText.writeln('• Name: ${recruiter.recruiterName ?? recruiter.name}');
    profileText.writeln('• Designation: ${recruiter.designation}');
    profileText.writeln('• Company: ${recruiter.company}');
    profileText.writeln(
      '• Status: ${recruiter.isVerified ? '✅ Verified' : '❌ Not Verified'}',
    );
    profileText.writeln();
    profileText.writeln('📞 Contact Details');
    profileText.writeln('• Email: ${recruiter.email}');
    profileText.writeln('• Phone: ${recruiter.phone}');
    profileText.writeln('• Location: ${recruiter.location}');
    if (recruiter.companyWebsite != null) {
      profileText.writeln();
      profileText.writeln('🌐 Company Website');
      profileText.writeln(recruiter.companyWebsite!);
    }
    profileText.writeln();
    profileText.writeln('=' * 40);
    profileText.writeln('📲 Download Airigo Job Portal App');
    profileText.writeln(
      'https://play.google.com/store/apps/details?id=com.aptitsolutions.airigo',
    );
    profileText.writeln();
    profileText.writeln('Shared via Airigo Job Portal');
    profileText.writeln('📅 ${DateTime.now().toString().split('.')[0]}');

    await Clipboard.setData(ClipboardData(text: profileText.toString()));

    AppScaffoldFeedback.show(
      context,
      message: 'Profile copied to clipboard',
      type: ResponseType.success,
    );
  }

  Widget _card({required Widget child, required Color borderColor}) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _sectionHeader(
    IconData icon,
    String title,
    bool isDark,
    ThemeData theme, {
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              'Change',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _editProfile(RecruiterModel? recruiter) {
    if (recruiter == null) return;

    final nameCtrl = TextEditingController(text: recruiter.recruiterName ?? '');
    final titleCtrl = TextEditingController(text: recruiter.designation ?? '');
    final companyCtrl = TextEditingController(text: recruiter.company ?? '');

    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: context.theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14.h),
            _textFieldCard(
              [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: "Name",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            _textFieldCard(
              [
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: "Job Title",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter job title';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            _textFieldCard(
              [
                TextFormField(
                  controller: companyCtrl,
                  decoration: InputDecoration(
                    hintText: "Company",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            SizedBox(height: 16.h),
            _saveBtn(() async {
              // Update profile using auth provider
              final updatedRecruiter = recruiter.copyWith(
                recruiterName: nameCtrl.text.isNotEmpty ? nameCtrl.text : null,
                designation: titleCtrl.text.isNotEmpty ? titleCtrl.text : null,
                company: companyCtrl.text.isNotEmpty ? companyCtrl.text : null,
              );

              try {
                await ref
                    .read(authStateProvider.notifier)
                    .updateProfile(updatedRecruiter.toJson());
                Navigator.pop(ctx);
                AppScaffoldFeedback.show(
                  context,
                  message: 'Profile updated successfully',
                  type: ResponseType.success,
                );
              } catch (e) {
                AppScaffoldFeedback.show(
                  context,
                  message: 'Failed to update profile: $e',
                  type: ResponseType.error,
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  void _editCompanyInfo(RecruiterModel? recruiter) {
    if (recruiter == null) return;

    final compCtrl = TextEditingController(text: recruiter.company ?? '');
    final titleCtrl = TextEditingController(text: recruiter.designation ?? '');
    final websiteCtrl = TextEditingController(
      text: recruiter.companyWebsite ?? '',
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: context.theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Company Info',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14.h),
            _textFieldCard(
              [
                TextFormField(
                  controller: compCtrl,
                  decoration: InputDecoration(
                    hintText: "Company Name",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            _textFieldCard(
              [
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: "Designation",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter designation';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            _textFieldCard(
              [
                TextFormField(
                  controller: websiteCtrl,
                  decoration: InputDecoration(
                    hintText: "Website",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter website';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            SizedBox(height: 16.h),
            _saveBtn(() async {
              // Update profile using auth provider
              final updatedRecruiter = recruiter.copyWith(
                company: compCtrl.text,
                designation: titleCtrl.text.isNotEmpty ? titleCtrl.text : null,
                companyWebsite: websiteCtrl.text.isNotEmpty
                    ? websiteCtrl.text
                    : null,
              );

              try {
                await ref
                    .read(authStateProvider.notifier)
                    .updateProfile(updatedRecruiter.toJson());
                Navigator.pop(ctx);
                AppScaffoldFeedback.show(
                  context,
                  message: 'Company info updated successfully',
                  type: ResponseType.success,
                );
              } catch (e) {
                AppScaffoldFeedback.show(
                  context,
                  message: 'Failed to update company info: $e',
                  type: ResponseType.error,
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  void _editContact(RecruiterModel? recruiter) {
    if (recruiter == null) return;

    final emailCtrl = TextEditingController(text: recruiter.email);
    final phoneCtrl = TextEditingController(text: recruiter.phone);
    final locCtrl = TextEditingController(text: recruiter.location);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: context.theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Contact Details',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14.h),
            _textFieldCard(
              [
                TextFormField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    hintText: "Email",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            _textFieldCard(
              [
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    hintText: "Phone",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            _textFieldCard(
              [
                TextFormField(
                  controller: locCtrl,
                  decoration: InputDecoration(
                    hintText: "Location",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
              ],
              isDark,
              theme,
            ),
            SizedBox(height: 16.h),
            _saveBtn(() async {
              // Update profile using auth provider
              final updatedRecruiter = recruiter.copyWith(
                email: emailCtrl.text,
                phone: phoneCtrl.text,
                location: locCtrl.text,
              );

              try {
                await ref
                    .read(authStateProvider.notifier)
                    .updateProfile(updatedRecruiter.toJson());
                Navigator.pop(ctx);
                AppScaffoldFeedback.show(
                  context,
                  message: 'Contact updated successfully',
                  type: ResponseType.success,
                );
              } catch (e) {
                AppScaffoldFeedback.show(
                  context,
                  message: 'Failed to update contact: $e',
                  type: ResponseType.error,
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final _formKey = GlobalKey<FormState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConf = true;
    String? errorMessage;
    String? successMessage;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: context.theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _textFieldCard(
                    [
                      TextFormField(
                        controller: oldCtrl,
                        obscureText: obscureOld,
                        decoration: InputDecoration(
                          hintText: "Current Password",
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOld
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureOld = !obscureOld;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current password';
                          }
                          return null;
                        },
                      ),
                    ],
                    isDark,
                    theme,
                  ),
                  _textFieldCard(
                    [
                      TextFormField(
                        controller: newCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          hintText: "New Password",
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                    isDark,
                    theme,
                  ),
                  _textFieldCard(
                    [
                      TextFormField(
                        controller: confCtrl,
                        obscureText: obscureConf,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConf
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConf = !obscureConf;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm password';
                          }
                          if (value != newCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                    isDark,
                    theme,
                  ),
                  SizedBox(height: 16.h),
                  // Error/Success message display
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (successMessage != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              successMessage!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (errorMessage != null || successMessage != null)
                    SizedBox(height: 16.h),
                  isLoading
                      ? const CircularProgressIndicator()
                      : _saveBtn(() async {
                          log('Update password button clicked');

                          // Clear previous messages
                          setState(() {
                            errorMessage = null;
                            successMessage = null;
                          });

                          // Validate form first
                          if (!_formKey.currentState!.validate()) {
                            log('Form validation failed');
                            return;
                          }

                          // Check if new password is similar to current password
                          if (oldCtrl.text == newCtrl.text) {
                            log('Password similarity check failed');
                            setState(() {
                              errorMessage =
                                  'New password cannot be the same as current password';
                            });
                            return;
                          }

                          log('Starting password update...');
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final authService = AuthService();
                            final result = await authService
                                .changePasswordWithValidation(
                                  currentPassword: oldCtrl.text,
                                  newPassword: newCtrl.text,
                                );

                            log('Password change result: $result');

                            if (result['success']) {
                              setState(() {
                                successMessage =
                                    result['message'] ??
                                    'Password changed successfully';
                                errorMessage = null;
                              });
                              // Clear controllers after successful change
                              oldCtrl.clear();
                              newCtrl.clear();
                              confCtrl.clear();
                              // Close the modal after showing success message
                              Future.delayed(
                                const Duration(milliseconds: 1500),
                                () {
                                  Navigator.pop(ctx);
                                },
                              );
                            } else {
                              setState(() {
                                errorMessage =
                                    result['message'] ??
                                    'Failed to change password';
                                successMessage = null;
                              });
                            }
                          } catch (e) {
                            log('Password change error: $e');
                            setState(() {
                              errorMessage = 'An error occurred: $e';
                              successMessage = null;
                            });
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }, label: 'Update Password'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActiveSessions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Sessions',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14.h),
            ...[
              ('iPhone 15 Pro', 'San Francisco, CA • Active now'),
              ('MacBook Pro', 'San Francisco, CA • 2 hours ago'),
              ('Chrome — Windows', 'New York, NY • Yesterday'),
            ].map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.devices,
                    color: AppColors.secondary,
                    size: 18.sp,
                  ),
                ),
                title: Text(
                  s.$1,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  s.$2,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
                ),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppScaffoldFeedback.show(
                      context,
                      message: 'Session revoked',
                      type: ResponseType.warning,
                    );
                  },
                  child: Text(
                    'Revoke',
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        title: Text(
          'Logout?',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You will be signed out of your RecruitHub account.',
          style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              Navigator.pop(ctx);
              AppScaffoldFeedback.show(
                context,
                message: 'Logged out',
                type: ResponseType.success,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
    );
  }

  Widget _saveBtn(VoidCallback onTap, {String label = 'Save Changes'}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildIdCardSection(
    ThemeData theme,
    bool isDark,
    RecruiterModel? recruiter,
    Color borderColor,
  ) {
    return _card(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.badge_outlined,
            'ID Card',
            isDark,
            theme,
            onTap: () => _pickAndUploadIdCard(),
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: GestureDetector(
              onTap: recruiter?.idCardUrl != null
                  ? () => _showIdCardFullScreen(recruiter!.idCardUrl!)
                  : null,
              child: Container(
                width: double.infinity,
                height: 180.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: recruiter?.idCardUrl != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          ShimmerImage(
                            imageUrl: recruiter!.idCardUrl!,
                            width: double.infinity,
                            height: 180.h,
                            borderRadius: 12.r,
                            errorWidget: _buildIdCardPlaceholder(theme, isDark),
                          ),
                          Positioned(
                            bottom: 8.h,
                            right: 8.h,
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildIdCardPlaceholder(theme, isDark),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              'Upload a clear image of your business ID card',
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdCardPlaceholder(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40.sp,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
        SizedBox(height: 8.h),
        Text(
          'No ID Card Uploaded',
          style: TextStyle(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadIdCard() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: context.theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload ID Card',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (image != null) {
                      _uploadIdCard(image.path);
                    }
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_outlined,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                    );
                    if (image != null) {
                      _uploadIdCard(image.path);
                    }
                  },
                ),
              ],
            ),
          ],
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

  Future<void> _uploadIdCard(String path) async {
    try {
      await ref.read(authStateProvider.notifier).updateIdCard(path);
      AppScaffoldFeedback.show(
        context,
        message: 'ID Card updated successfully',
        type: ResponseType.success,
      );
    } catch (e) {
      AppScaffoldFeedback.show(
        context,
        message: 'Failed to update ID Card: $e',
        type: ResponseType.error,
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Photo',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (image != null) {
                      _uploadImage(image.path);
                    }
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_outlined,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                    );
                    if (image != null) {
                      _uploadImage(image.path);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 24.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  Future<void> _uploadImage(String path) async {
    try {
      await ref.read(authStateProvider.notifier).updateProfileImage(path);
      AppScaffoldFeedback.show(
        context,
        message: 'Profile photo updated successfully',
        type: ResponseType.success,
      );
    } catch (e) {
      AppScaffoldFeedback.show(
        context,
        message: 'Failed to update profile photo: $e',
        type: ResponseType.error,
      );
    }
  }

  Widget _textFieldCard(List<Widget> children, bool isDark, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                message,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppBar icon button
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: context.theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
