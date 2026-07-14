import 'package:airigo_jobportal/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF121620) : Colors.white).withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                Iconsax.chart,
                'Dashboard',
                currentIndex == 0,
                isDark,
                0,
                context,
              ),
              _buildNavItem(
                Iconsax.profile_2user,
                'Jobseekers',
                currentIndex == 1,
                isDark,
                1,
                context,
              ),
              _buildNavItem(
                Iconsax.building,
                'Recruiters',
                currentIndex == 2,
                isDark,
                2,
                context,
              ),
              _buildNavItem(
                Iconsax.briefcase,
                'Jobs',
                currentIndex == 3,
                isDark,
                3,
                context,
              ),
              // _buildNavItem(
              //   Iconsax.document_text,
              //   'Applications',
              //   currentIndex == 4,
              //   isDark,
              //   4,
              //   context,
              // ),
              _buildNavItem(
                Iconsax.flag,
                'Issues',
                currentIndex == 4,
                isDark,
                4,
                context,
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
    BuildContext context,
  ) {
    final Color color = isActive
        ? isDark
            ? Colors.white
            : AppTheme.primaryBrand
        : (isDark ? Colors.grey.shade400 : Colors.grey);

    return GestureDetector(
      onTap: () => onTap(index),
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
            Icon(icon, color: color, size: 22.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isActive ? 10.sp : 9.sp,
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
