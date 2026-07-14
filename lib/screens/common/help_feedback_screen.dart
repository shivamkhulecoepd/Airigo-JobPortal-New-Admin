// ======================= HELP & FEEDBACK =======================
import 'package:airigo_jobportal/services/api/issue_report_service.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/utils/extensions.dart';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedType = 'feedback'; // Default to feedback
  bool _isLoading = false;

  void _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final service = IssueReportService();
        final result = await service.createIssueReport(
          type: _selectedType,
          title: _titleController.text,
          description: _controller.text,
        );

        if (result['success']) {
          AppScaffoldFeedback.show(
            context,
            message: result['message'] ?? 'Feedback submitted successfully!',
            type: ResponseType.success,
          );
          // Clear the form after successful submission
          _titleController.clear();
          _controller.clear();
          setState(() {
            _selectedType = 'feedback';
          });
          
          // Navigate back to previous screen after successful submission
          Navigator.pop(context);
        } else {
          AppScaffoldFeedback.show(
            context,
            message: result['message'] ?? 'Failed to submit feedback',
            type: ResponseType.error,
          );
        }
      } catch (e) {
        AppScaffoldFeedback.show(
          context,
          message: 'An error occurred: $e',
          type: ResponseType.error,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
              'Help & Feedback',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),

                    // Feedback type selection
                    _card([
                      _tile(
                        icon: _selectedType == 'feedback' ? Iconsax.message_text : Iconsax.danger,
                        title: "Type",
                        subtitle: _selectedType == 'feedback' ? "Feedback" : "Issue",
                        isDark: isDark,
                        theme: theme,
                        onTap: () {
                          _showTypeSelectionDialog(context, theme);
                        },
                      ),
                    ], isDark, theme),

                    SizedBox(height: 16.h),

                    // Title field
                    _card([
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: "Brief title for your ${_selectedType == 'feedback' ? 'feedback' : 'issue'}...",
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a title";
                          }
                          if (value.length < 5) {
                            return "Title should be at least 5 characters";
                          }
                          return null;
                        },
                      ),
                    ], isDark, theme),

                    SizedBox(height: 16.h),

                    // Description field
                    _card([
                      TextFormField(
                        controller: _controller,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: "Write your ${_selectedType == 'feedback' ? 'feedback' : 'issue'} in detail...",
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please describe your ${_selectedType == 'feedback' ? 'feedback' : 'issue'}";
                          }
                          if (value.length < 10) {
                            return "${_selectedType == 'feedback' ? 'Feedback' : 'Issue'} should be at least 10 characters";
                          }
                          return null;
                        },
                      ),
                    ], isDark, theme),

                    SizedBox(height: 16.h),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submitFeedback,
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text("Submit ${_selectedType == 'issue' ? 'Issue' : 'Feedback'}"),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.1),
                            AppColors.accent.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Our team will get back to you within 24 hours.",
                      ),
                    ),
                  ],
                ),
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
    VoidCallback? onTap,
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
      onTap: onTap,
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

  void _showTypeSelectionDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          title: Text("Select Type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text("Feedback"),
                value: "feedback",
                groupValue: _selectedType,
                onChanged: (String? value) {
                  setState(() {
                    _selectedType = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text("Issue"),
                value: "issue",
                groupValue: _selectedType,
                onChanged: (String? value) {
                  setState(() {
                    _selectedType = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}