import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class CommonNavBar extends StatefulWidget {
  final String role;
  final int currentIndex;
  final Function(int) onTap;
  const CommonNavBar({
    required this.role, required this.currentIndex, required this.onTap, super.key,
  });

  @override
  State<CommonNavBar> createState() => _CommonNavBarState();
}

class _CommonNavBarState extends State<CommonNavBar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF121620) : Colors.white).withValues(
          alpha: 0.9,
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 8.h),
          child: (widget.role == 'jobseeker')
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(
                      Iconsax.home,
                      'Home',
                      widget.currentIndex == 0,
                      isDark,
                      0,
                    ),
                    _buildNavItem(
                      Iconsax.global_search,
                      'Explore',
                      widget.currentIndex == 1,
                      isDark,
                      1,
                    ),
                    _buildNavItem(
                      Iconsax.briefcase,
                      'Applications',
                      widget.currentIndex == 2,
                      isDark,
                      2,
                    ),
                    _buildNavItem(
                      Iconsax.tag_user,
                      'Profile',
                      widget.currentIndex == 3,
                      isDark,
                      3,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(
                      Iconsax.home,
                      'Home',
                      widget.currentIndex == 0,
                      isDark,
                      0,
                    ),
                    _buildNavItem(
                      Iconsax.briefcase,
                      'Jobs',
                      widget.currentIndex == 1,
                      isDark,
                      1,
                    ),
                    _buildNavItem(
                      Iconsax.add_square,
                      'Post',
                      widget.currentIndex == 2,
                      isDark,
                      2,
                    ),
                    _buildNavItem(
                      Iconsax.user_search,
                      'Applicants',
                      widget.currentIndex == 3,
                      isDark,
                      3,
                    ),
                    _buildNavItem(
                      Iconsax.tag_user,
                      'Profile',
                      widget.currentIndex == 4,
                      isDark,
                      4,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    bool isDark,
    int index,
  ) {
    final Color color = isActive
        ? isDark
              ? Colors.white
              : context.theme.colorScheme.primary
        : (isDark ? Colors.grey.shade400 : Colors.grey);

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        padding: EdgeInsets.only(top: 8.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isActive ? color : Colors.transparent,
              width: 3.w,
            ),
          ),
          borderRadius: BorderRadius.circular(3.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: isActive ? 11.sp : 10.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
