import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ResponseType { success, error, warning, info }

class AppScaffoldFeedback {
  static void show(
    BuildContext context, {
    required String message,
    ResponseType type = ResponseType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionText,
    VoidCallback? onAction,
  }) {
    final config = _getConfig(type);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
      content: _SnackContent(
        message: message,
        icon: config.icon,
        color: config.color,
        actionText: actionText,
        onAction: onAction,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static _ResponseConfig _getConfig(ResponseType type) {
    switch (type) {
      case ResponseType.success:
        return _ResponseConfig(
          icon: Icons.check_circle,
          color: const Color(0xFF22C55E),
        );

      case ResponseType.error:
        return _ResponseConfig(
          icon: Icons.error,
          color: const Color(0xFFEF4444),
        );

      case ResponseType.warning:
        return _ResponseConfig(
          icon: Icons.warning,
          color: const Color(0xFFF59E0B),
        );

      // case ResponseType.info:
      default:
        return _ResponseConfig(
          icon: Icons.info,
          color: const Color(0xFF3B82F6),
        );
    }
  }
}

class _ResponseConfig {
  final IconData icon;
  final Color color;

  _ResponseConfig({required this.icon, required this.color});
}

class _SnackContent extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final String? actionText;
  final VoidCallback? onAction;

  const _SnackContent({
    required this.message,
    required this.icon,
    required this.color,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26.sp),

          SizedBox(width: 12.w),

          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),

          if (actionText != null && onAction != null) ...[
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                actionText!,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
