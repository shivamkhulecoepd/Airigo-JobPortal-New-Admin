import 'dart:io';
import 'package:airigo_jobportal/widgets/app_scaffold_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:airigo_jobportal/core/providers/auth_provider.dart';
import '../../core/providers/jobseeker_profile_provider.dart';
import '../../utils/app_colors.dart';

class JobseekerEditProfileScreen extends ConsumerStatefulWidget {
  const JobseekerEditProfileScreen({super.key});

  @override
  ConsumerState<JobseekerEditProfileScreen> createState() =>
      _JobseekerEditProfileScreenState();
}

class _JobseekerEditProfileScreenState
    extends ConsumerState<JobseekerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();

  String? _selectedDateOfBirth;
  File? _selectedImage;
  String? _selectedResumePath;
  bool _isUploadingImage = false;
  bool _isUploadingResume = false;
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    // Fetch profile from API to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobseekerProfileProvider.notifier).fetchProfile();
    });
    _loadProfileData();
  }

  void _loadProfileData() {
    // Try to get from jobseekerProfileProvider first
    final profileState = ref.read(jobseekerProfileProvider);
    final profile = profileState.profile;

    if (profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _qualificationController.text = profile.qualification ?? '';
      _locationController.text = profile.location;
      _bioController.text = profile.bio ?? '';
      _experienceController.text = profile.experienceYears.toString();
      _skillsController.text = profile.skills.join(', ');
      _selectedDateOfBirth = profile.dateOfBirth;
    } else {
      // Fallback to auth provider
      final jobseeker = ref.read(currentJobseekerProvider);
      if (jobseeker != null) {
        _nameController.text = jobseeker.name;
        _phoneController.text = jobseeker.phone;
        _qualificationController.text = jobseeker.qualification ?? '';
        _locationController.text = jobseeker.location;
        _bioController.text = jobseeker.bio ?? '';
        _experienceController.text = jobseeker.experienceYears.toString();
        _skillsController.text = jobseeker.skills.join(', ');
        _selectedDateOfBirth = jobseeker.dateOfBirth;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Show upload dialog
        _showUploadDialog('Uploading profile image...');

        final success = await ref
            .read(jobseekerProfileProvider.notifier)
            .updateProfileImage(image.path);

        Navigator.pop(context); // Close loading dialog

        if (success) {
          if (mounted) {
            AppScaffoldFeedback.show(
              context,
              message: 'Profile image updated successfully !',
              type: ResponseType.success,
            );
          }
        } else {
          if (mounted) {
            AppScaffoldFeedback.show(
              context,
              message: 'Failed to update profile image',
              type: ResponseType.error,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppScaffoldFeedback.show(
          context,
          message: 'Error while uploading profile image: $e',
          type: ResponseType.error,
        );
      }
    }
  }

  Future<void> _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;

        // Show confirmation if file is large
        if (fileSize > 3 * 1024 * 1024) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Large File'),
              content: Text(
                'File size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB. Continue with upload?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );

          if (confirm != true) return;
        }

        setState(() {
          _selectedResumePath = filePath;
        });

        // Show upload dialog
        _showUploadDialog('Uploading resume...');

        final success = await ref
            .read(jobseekerProfileProvider.notifier)
            .updateResume(filePath);

        Navigator.pop(context); // Close loading dialog

        if (success) {
          if (mounted) {
            AppScaffoldFeedback.show(
              context,
              message: 'Resume uploaded: $fileName',
              type: ResponseType.success,
            );
          }
        } else {
          if (mounted) {
            AppScaffoldFeedback.show(
              context,
              message: 'Failed to upload resume',
              type: ResponseType.error,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppScaffoldFeedback.show(
          context,
          message: 'Error while uploading resume: $e',
          type: ResponseType.error,
        );
      }
    }
  }

  void _showUploadDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth != null
          ? DateTime.parse(_selectedDateOfBirth!)
          : DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _saveAllDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSavingAll = true;
    });

    bool allSuccess = true;

    try {
      // 1. Update personal details
      final personalSuccess = await ref
          .read(jobseekerProfileProvider.notifier)
          .updatePersonalDetails(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      allSuccess = allSuccess && personalSuccess;

      // 2. Update education
      final educationSuccess = await ref
          .read(jobseekerProfileProvider.notifier)
          .updateEducation(
            qualification: _qualificationController.text.trim(),
            dateOfBirth: _selectedDateOfBirth,
          );
      allSuccess = allSuccess && educationSuccess;

      // 3. Update experience
      final experience = int.tryParse(_experienceController.text.trim());
      if (experience != null) {
        final experienceSuccess = await ref
            .read(jobseekerProfileProvider.notifier)
            .updateExperience(experience: experience);
        allSuccess = allSuccess && experienceSuccess;
      }

      // 4. Update location
      if (_locationController.text.trim().isNotEmpty) {
        final locationSuccess = await ref
            .read(jobseekerProfileProvider.notifier)
            .updateLocation(location: _locationController.text.trim());
        allSuccess = allSuccess && locationSuccess;
      }

      // 5. Update bio
      final bioSuccess = await ref
          .read(jobseekerProfileProvider.notifier)
          .updateBio(bio: _bioController.text.trim());
      allSuccess = allSuccess && bioSuccess;

      // 6. Update skills (if any entered)
      if (_skillsController.text.trim().isNotEmpty) {
        final skills = _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (skills.isNotEmpty) {
          final skillsSuccess = await ref
              .read(jobseekerProfileProvider.notifier)
              .updateSkills(skills: skills);
          allSuccess = allSuccess && skillsSuccess;
        }
      }

      if (mounted) {
        if (allSuccess) {
          AppScaffoldFeedback.show(
            context,
            message: 'All details updated successfully!',
            type: ResponseType.success,
          );

          // Refresh auth state to sync across all screens
          await ref.read(authStateProvider.notifier).refresh();

          // Pop back to previous screen
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          AppScaffoldFeedback.show(
            context,
            message: 'Some updates failed. Please try again.',
            type: ResponseType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppScaffoldFeedback.show(
          context,
          message: 'Error while updating all details: $e',
          type: ResponseType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAll = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(jobseekerProfileProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(jobseekerProfileProvider.notifier).fetchProfile();
          _loadProfileData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Section
                _buildProfileImageSection(profile),
                SizedBox(height: 24.h),

                // Personal Details Section
                _buildSectionCard(
                  title: 'Personal Details',
                  icon: Iconsax.user,
                  children: [
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Iconsax.user,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    _buildTextFormField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Iconsax.call,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Education Section
                _buildSectionCard(
                  title: 'Education',
                  icon: Iconsax.book,
                  children: [
                    _buildTextFormField(
                      controller: _qualificationController,
                      label: 'Qualification',
                      icon: Iconsax.grammerly,
                    ),
                    SizedBox(height: 16.h),
                    _buildDateSelector(
                      selectedDate: _selectedDateOfBirth,
                      onTap: _selectDate,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Experience Section
                _buildSectionCard(
                  title: 'Experience',
                  icon: Iconsax.briefcase,
                  children: [
                    _buildTextFormField(
                      controller: _experienceController,
                      label: 'Years of Experience',
                      icon: Iconsax.clock,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Location Section
                _buildSectionCard(
                  title: 'Location',
                  icon: Iconsax.location,
                  children: [
                    _buildTextFormField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Iconsax.location,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Skills Section
                _buildSectionCard(
                  title: 'Skills',
                  icon: Iconsax.star,
                  children: [
                    _buildTextFormField(
                      controller: _skillsController,
                      label: 'Skills (comma separated)',
                      icon: Iconsax.star,
                      maxLines: 3,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Example: Flutter, Dart, Python',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Bio Section
                _buildSectionCard(
                  title: 'Bio',
                  icon: Iconsax.note,
                  children: [
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        labelText: 'Tell us about yourself',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Resume Upload Section
                _buildResumeUploadSection(profile),
                SizedBox(height: 24.h),

                // Save All Button
                _buildSaveAllButton(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(profile) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade50,
                    width: 2.w,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: CircleAvatar(
                  radius: 60.r,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (profile?.avatarUrl != null
                                ? NetworkImage(profile!.avatarUrl!)
                                : null)
                            as ImageProvider?,
                  child: _selectedImage == null && profile?.avatarUrl == null
                      ? Icon(Iconsax.user, size: 60.sp, color: Colors.grey[400])
                      : null,
                ),
              ),
              if (_isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Iconsax.camera,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap to change profile photo',
            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.sp),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    String? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              selectedDate != null
                  ? DateTime.parse(
                      selectedDate,
                    ).toLocal().toString().split(' ')[0]
                  : 'Select Date of Birth',
              style: TextStyle(
                fontSize: 16.sp,
                // color: selectedDate != null ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeUploadSection(profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Iconsax.document,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Resume',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (profile?.resumeFilename != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.document_text,
                      color: Colors.green,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        profile!.resumeFilename!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.green[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],
            if (_isUploadingResume)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _pickResume,
                icon: Icon(Iconsax.document_upload),
                label: const Text('Upload Resume'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            SizedBox(height: 8.h),
            Text(
              'Supported formats: PDF, DOC, DOCX (Max 5MB)',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveAllButton() {
    return Card(
      elevation: 4,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(Iconsax.save_2, size: 40.sp, color: Colors.white),
            SizedBox(height: 8.h),
            Text(
              'Save All Changes',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Update all profile sections at once',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isSavingAll ? null : _saveAllDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSavingAll
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.save_2,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Save All',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
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
}
