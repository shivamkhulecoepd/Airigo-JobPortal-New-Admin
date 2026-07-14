import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            surfaceTintColor: theme.colorScheme.surface,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
            title: Text(
              'About App',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),

                  /// Logo
                  Container(
                    height: 140.w,
                    width: 140.w,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/Airigo-jobs-logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  /// App Name
                  Text(
                    "Airiogo Jobs",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  /// Version
                  Text(
                    "2.0.1",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  /// Website + Social
                  _card(
                    [
                      _tile(
                        icon: Iconsax.global,
                        title: "Website",
                        subtitle: "https://airigojobs.com",
                        isDark: isDark,
                        theme: theme,
                      ),
                      Divider(
                        height: 0,
                        thickness: 2.h,
                        color: isDark
                            ? AppColors.cardDark
                            : Colors.grey.shade100,
                      ),
                      _tile(
                        icon: Iconsax.instagram,
                        title: "Instagram",
                        subtitle: "@airigojobs",
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],
                    isDark,
                    theme,
                  ),

                  /// Legal
                  _card(
                    [
                      _tile(
                        icon: Iconsax.setting,
                        title: "Open Source Licenses",
                        isDark: isDark,
                        theme: theme,
                      ),
                      Divider(
                        height: 0,
                        thickness: 2.h,
                        color: isDark
                            ? AppColors.cardDark
                            : Colors.grey.shade100,
                      ),
                      _tile(
                        icon: Iconsax.document,
                        title: "Terms of Use",
                        isDark: isDark,
                        theme: theme,
                      ),
                      Divider(
                        height: 0,
                        thickness: 2.h,
                        color: isDark
                            ? AppColors.cardDark
                            : Colors.grey.shade100,
                      ),
                      _tile(
                        // icon: Iconsax.shield_security2,
                        icon: Iconsax.security_user,
                        title: "Privacy Policy",
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],
                    isDark,
                    theme,
                  ),

                  /// Share
                  _card(
                    [
                      _tile(
                        icon: Iconsax.share,
                        title: "Share App",
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],
                    isDark,
                    theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool? isDark,
    required ThemeData theme,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12.sp,
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right, size: 20.sp),
      onTap: () {},
    );
  }

  Widget _card(List<Widget> children, bool isDark, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
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
