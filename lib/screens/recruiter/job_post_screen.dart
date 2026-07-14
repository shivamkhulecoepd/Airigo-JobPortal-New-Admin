import 'dart:io';
import 'package:airigo_jobportal/screens/authentication/auth_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/manage_postings_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/recruiter_main_screen.dart';
import 'package:airigo_jobportal/utils/app_colors.dart';
import 'package:airigo_jobportal/widgets/shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:airigo_jobportal/models/job_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/storage/pending_job_service.dart';
import '../../widgets/app_scaffold_feedback.dart';

class JobPostScreen extends ConsumerStatefulWidget {
  final JobModel? job;
  final bool isBackButton;
  const JobPostScreen({super.key, this.job, required this.isBackButton});

  @override
  ConsumerState<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends ConsumerState<JobPostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();
  final _companyUrlCtrl = TextEditingController();

  // State
  final List<String> _skills = [];
  final List<String> _requirements = [];
  final List<String> _perks = [];

  String _selectedCategory = 'Airline';
  String _selectedJobType = 'Full-time';
  String _selectedExperience = '0-1 year';
  String _selectedSalaryMin = '1';
  String _selectedSalaryMax = '5';
  bool _isLoading = false;
  bool _isActive = true;
  bool _isUrgentHiring = false;
  String? _companyLogoPath; // Local file path for new image selection
  String? _existingLogoUrl; // URL of existing logo
  bool _isUploadingLogo = false; // Track upload progress

  // Focus nodes for animated labels
  final _titleFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _descFocus = FocusNode();
  final _urlFocus = FocusNode();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _categories = ['Airline', 'Hospitality', 'Cruise'];
  static const _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Remote Only',
  ];
  static const _experienceOptions = [
    '0-1 year',
    '1-3 years',
    '3-5 years',
    '5-8 years',
    '8+ years',
  ];
  static const _salaryOptions = [
    '1',
    '3',
    '5',
    '10',
    '15',
    '18',
    '20',
    '25',
    '30',
    '35',
    '40+',
  ];

  // Category icons
  static const Map<String, IconData> _categoryIcons = {
    'Airline': Icons.flight_outlined,
    'Hospitality': Icons.hotel_outlined,
    'Cruise': Icons.directions_boat_outlined,
  };

  List<String> get _perksOptions {
    switch (_selectedCategory.toLowerCase()) {
      case 'airline':
        return [
          'Free / Discounted Flights',
          'Travel Allowance',
          'Layover Accommodation',
          'Meal Allowance',
          'Uniform Allowance',
          'Medical Insurance',
          'Life Insurance',
          'Retirement Benefits',
          'Staff Travel for Family',
          'Paid Time Off',
          'Flexible Rosters',
          'International Exposure',
          'Airport Transport',
          'Training Programs',
        ];
      case 'hospitality':
        return [
          'Free Meals During Shift',
          'Staff Housing',
          'Service Charge / Tips',
          'Health Insurance',
          'Paid Leave',
          'Uniform Provided',
          'Laundry Services',
          'Hotel Stay Discounts',
          'F&B Discounts',
          'Career Growth',
          'Training Programs',
          'Flexible Shifts',
          'Transportation',
          'Performance Bonuses',
        ];
      case 'cruise':
        return [
          'Tax-Free Salary',
          'Free Accommodation Onboard',
          'Free Meals',
          'Worldwide Travel',
          'Completion Bonus',
          'Medical Insurance',
          'Paid Vacation',
          'Uniform Provided',
          'Laundry Services',
          'Onboard Recreation',
          'Internet Access',
          'Career Advancement',
          'Multi-Cultural Work Environment',
          'Port Transportation',
        ];
      default:
        return [
          'Health Insurance',
          'Remote Work',
          'Flexible Hours',
          'Stock Options',
          'Annual Bonus',
          'Learning Budget',
          'Gym Membership',
          'Free Meals',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    if (widget.job != null) _populateFields();
  }

  void _populateFields() {
    final job = widget.job!;
    _titleCtrl.text = job.designation;
    _companyNameCtrl.text = job.companyName;
    _selectedCategory = _categories.contains(job.category)
        ? job.category
        : 'Airline';
    _selectedJobType = _jobTypes.contains(job.jobType)
        ? job.jobType
        : 'Full-time';
    _locationCtrl.text = job.location;
    _descCtrl.text = job.description ?? '';
    if (job.skillsRequired != null) _skills.addAll(job.skillsRequired!);
    if (job.requirements != null) _requirements.addAll(job.requirements!);
    if (job.perksAndBenefits != null) _perks.addAll(job.perksAndBenefits!);
    _companyUrlCtrl.text = job.companyUrl ?? '';
    _isActive = job.isActive;
    _isUrgentHiring = job.isUrgentHiring;
    _selectedExperience = _experienceOptions.contains(job.experienceRequired)
        ? job.experienceRequired ?? '0-1 year'
        : '0-1 year';
    final parts = job.ctc.split('-');
    final rawMin = parts.isNotEmpty
        ? parts[0].replaceAll(RegExp(r'[^0-9+]'), '')
        : '1';
    final rawMax = parts.length > 1
        ? parts[1].split(' ')[0].replaceAll(RegExp(r'[^0-9+]'), '')
        : '5';
    _selectedSalaryMin = _salaryOptions.contains(rawMin) ? rawMin : '1';
    _selectedSalaryMax = _salaryOptions.contains(rawMax) ? rawMax : '5';

    // Set existing logo URL but keep _companyLogoPath null (no new file selected)
    _existingLogoUrl = job.companyLogoUrl;
    _companyLogoPath = null; // No new file selected initially
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _skillCtrl.dispose();
    _reqCtrl.dispose();
    _companyUrlCtrl.dispose();
    _companyNameCtrl.dispose();
    _titleFocus.dispose();
    _companyFocus.dispose();
    _locationFocus.dispose();
    _descFocus.dispose();
    _urlFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _selectCompanyLogo() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _companyLogoPath = picked.path;
      });
      // Note: Logo will be uploaded to Firebase along with job creation
      // No need for separate upload - backend handles it automatically
    }
  }

  void _updateCategoryAndClearPerks(String category) {
    setState(() {
      _selectedCategory = category;
      _perks.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        // forceMaterialTransparency: true,
        elevation: 1,
        shadowColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

        automaticallyImplyLeading: false,

        leading: widget.isBackButton
            ? IconButton(
                // onPressed: () => Navigator.of(context).pop(),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18.sp,
                  color: theme.colorScheme.onSurface,
                ),
              )
            : null,
        title: Text(
          widget.job != null ? 'Edit Job' : 'Post a Job',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        // centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: TextButton(
              onPressed: _isLoading ? null : _submitForm,
              style: TextButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                textStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              child: Text(
                widget.job != null ? 'Update' : 'Publish',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // ── Body ──────────────────────────────────────────────────
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Section 1: Company ─────────────────────
                            _SectionHeader(
                              step: '01',
                              title: 'Company Details',
                              subtitle: 'Tell us about your organisation',
                              textColor: textColor,
                              labelColor: labelColor,
                              accentColor: accentColor,
                            ),
                            SizedBox(height: 12.h),
                            _Card(
                              bg: theme.scaffoldBackgroundColor,
                              border: borderColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Company logo upload — minimal strip
                                  _LogoUploadTile(
                                    logoPath: _companyLogoPath,
                                    existingLogoUrl: _existingLogoUrl,
                                    onTap: _selectCompanyLogo,
                                    onRemove: () =>
                                        setState(() => _companyLogoPath = null),
                                    accentColor: accentColor,
                                    textColor: textColor,
                                    labelColor: labelColor,
                                    borderColor: borderColor,
                                    subtleFill: subtleFill,
                                  ),
                                  _Divider(color: borderColor),
                                  SizedBox(height: 10.h),
                                  _FieldGroup(
                                    label: 'Company Name',
                                    labelColor: labelColor,
                                    child: _StyledTextField(
                                      controller: _companyNameCtrl,
                                      hint: 'e.g. IndiGo Airlines',
                                      focusNode: _companyFocus,
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  _FieldGroup(
                                    label: 'Website URL',
                                    labelColor: labelColor,
                                    optional: true,
                                    child: _StyledTextField(
                                      controller: _companyUrlCtrl,
                                      hint: 'https://company.com',
                                      focusNode: _urlFocus,
                                      prefixIcon: Icons.language_outlined,
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      subtleFill: subtleFill,
                                      keyboardType: TextInputType.url,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // ── Section 2: Role ────────────────────────
                            _SectionHeader(
                              step: '02',
                              title: 'Role Details',
                              subtitle: 'Define the position',
                              textColor: textColor,
                              labelColor: labelColor,
                              accentColor: accentColor,
                            ),
                            SizedBox(height: 12.h),
                            _Card(
                              bg: theme.scaffoldBackgroundColor,
                              border: borderColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldGroup(
                                    label: 'Job Title',
                                    labelColor: labelColor,
                                    child: _StyledTextField(
                                      controller: _titleCtrl,
                                      hint: 'e.g. Senior Cabin Crew',
                                      focusNode: _titleFocus,
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // Category picker — pill style
                                  _FieldGroup(
                                    label: 'Category',
                                    labelColor: labelColor,
                                    child: _CategoryPicker(
                                      categories: _categories,
                                      selected: _selectedCategory,
                                      icons: _categoryIcons,
                                      onChanged: _updateCategoryAndClearPerks,
                                      accentColor: accentColor,
                                      textColor: textColor,
                                      labelColor: labelColor,
                                      borderColor: borderColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // Job Type — compact segmented
                                  _FieldGroup(
                                    label: 'Employment Type',
                                    labelColor: labelColor,
                                    child: _StyledDropdown(
                                      value: _selectedJobType,
                                      items: _jobTypes,
                                      onChanged: (v) => setState(
                                        () => _selectedJobType =
                                            v ?? _selectedJobType,
                                      ),
                                      hint: 'Select type',
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  _FieldGroup(
                                    label: 'Location',
                                    labelColor: labelColor,
                                    child: _StyledTextField(
                                      controller: _locationCtrl,
                                      hint: 'e.g. Mumbai, India',
                                      focusNode: _locationFocus,
                                      prefixIcon: Icons.location_on_outlined,
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // ── Section 3: Description ─────────────────
                            _SectionHeader(
                              step: '03',
                              title: 'Description',
                              subtitle: 'Describe the role & environment',
                              textColor: textColor,
                              labelColor: labelColor,
                              accentColor: accentColor,
                            ),
                            SizedBox(height: 12.h),
                            _Card(
                              bg: theme.scaffoldBackgroundColor,
                              border: borderColor,
                              child: _StyledTextField(
                                controller: _descCtrl,
                                hint:
                                    'Describe the role, team culture, and a typical day on the job...',
                                focusNode: _descFocus,
                                minLines: 5,
                                maxLines: 12,
                                textColor: textColor,
                                hintColor: labelColor,
                                borderColor: borderColor,
                                accentColor: accentColor,
                                subtleFill: subtleFill,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // ── Section 4: Requirements ────────────────
                            _SectionHeader(
                              step: '04',
                              title: 'Requirements',
                              subtitle: 'Skills, experience & compensation',
                              textColor: textColor,
                              labelColor: labelColor,
                              accentColor: accentColor,
                            ),
                            SizedBox(height: 12.h),
                            _Card(
                              bg: theme.scaffoldBackgroundColor,
                              border: borderColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Skills input
                                  _FieldGroup(
                                    label: 'Required Skills',
                                    labelColor: labelColor,
                                    child: _ChipInputField(
                                      controller: _skillCtrl,
                                      hint: 'Type a skill & press Enter',
                                      prefixIcon: Icons.bolt_outlined,
                                      onAdd: _addSkill,
                                      chips: _skills,
                                      onRemoveChip: (s) =>
                                          setState(() => _skills.remove(s)),
                                      accentColor: accentColor,
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  _Divider(color: borderColor),
                                  SizedBox(height: 16.h),

                                  // Requirements input
                                  _FieldGroup(
                                    label: 'Job Requirements',
                                    labelColor: labelColor,
                                    child: _ChipInputField(
                                      controller: _reqCtrl,
                                      hint: 'e.g. Valid passport required',
                                      prefixIcon: Icons.checklist_outlined,
                                      onAdd: _addReq,
                                      chips: _requirements,
                                      onRemoveChip: (r) => setState(
                                        () => _requirements.remove(r),
                                      ),
                                      accentColor: accentColor,
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  _Divider(color: borderColor),
                                  SizedBox(height: 16.h),

                                  // Experience
                                  _FieldGroup(
                                    label: 'Experience Required',
                                    labelColor: labelColor,
                                    child: _StyledDropdown(
                                      value: _selectedExperience,
                                      items: _experienceOptions,
                                      onChanged: (v) => setState(
                                        () => _selectedExperience =
                                            v ?? _selectedExperience,
                                      ),
                                      hint: 'Select experience level',
                                      textColor: textColor,
                                      hintColor: labelColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // Salary range
                                  _FieldGroup(
                                    label: 'Annual CTC (in LPA)',
                                    labelColor: labelColor,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _StyledDropdown(
                                            value: _selectedSalaryMin,
                                            items: _salaryOptions,
                                            onChanged: (v) => setState(
                                              () => _selectedSalaryMin =
                                                  v ?? _selectedSalaryMin,
                                            ),
                                            hint: 'Min',
                                            textColor: textColor,
                                            hintColor: labelColor,
                                            borderColor: borderColor,
                                            accentColor: accentColor,
                                            subtleFill: subtleFill,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                          ),
                                          child: Text(
                                            '—',
                                            style: TextStyle(
                                              color: labelColor,
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: _StyledDropdown(
                                            value: _selectedSalaryMax,
                                            items: _salaryOptions,
                                            onChanged: (v) => setState(
                                              () => _selectedSalaryMax =
                                                  v ?? _selectedSalaryMax,
                                            ),
                                            hint: 'Max',
                                            textColor: textColor,
                                            hintColor: labelColor,
                                            borderColor: borderColor,
                                            accentColor: accentColor,
                                            subtleFill: subtleFill,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // ── Section 5: Settings & Perks ────────────
                            _SectionHeader(
                              step: '05',
                              title: 'Settings & Perks',
                              subtitle: 'Visibility and benefits',
                              textColor: textColor,
                              labelColor: labelColor,
                              accentColor: accentColor,
                            ),
                            SizedBox(height: 12.h),
                            _Card(
                              bg: theme.scaffoldBackgroundColor,
                              border: borderColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Toggle tiles
                                  _ToggleTile(
                                    title: 'Active Listing',
                                    subtitle: 'Visible to all candidates',
                                    icon: Icons.visibility_outlined,
                                    value: _isActive,
                                    onChanged: (v) =>
                                        setState(() => _isActive = v),
                                    accentColor: accentColor,
                                    textColor: textColor,
                                    labelColor: labelColor,
                                    subtleFill: subtleFill,
                                  ),
                                  _Divider(color: borderColor),
                                  _ToggleTile(
                                    title: 'Urgent Hiring',
                                    subtitle:
                                        'Highlights listing to attract faster',
                                    icon: Icons.flash_on_outlined,
                                    value: _isUrgentHiring,
                                    onChanged: (v) =>
                                        setState(() => _isUrgentHiring = v),
                                    accentColor: accentColor,
                                    textColor: textColor,
                                    labelColor: labelColor,
                                    subtleFill: subtleFill,
                                  ),
                                  _Divider(color: borderColor),
                                  SizedBox(height: 16.h),

                                  // Perks
                                  _FieldGroup(
                                    label: 'Perks & Benefits',
                                    labelColor: labelColor,
                                    child: _PerksGrid(
                                      options: _perksOptions,
                                      selected: _perks,
                                      onToggle: (perk) => setState(() {
                                        _perks.contains(perk)
                                            ? _perks.remove(perk)
                                            : _perks.add(perk);
                                      }),
                                      accentColor: accentColor,
                                      textColor: textColor,
                                      labelColor: labelColor,
                                      borderColor: borderColor,
                                      subtleFill: subtleFill,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 28.h),

                            // ── Submit Button ──────────────────────────
                            _SubmitButton(
                              isLoading: _isLoading,
                              isEdit: widget.job != null,
                              onTap: _submitForm,
                              accentColor: accentColor,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              // child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _addSkill() {
    final s = _skillCtrl.text.trim();
    if (s.isNotEmpty && !_skills.contains(s)) {
      setState(() {
        _skills.add(s);
        _skillCtrl.clear();
      });
    }
  }

  void _addReq() {
    final r = _reqCtrl.text.trim();
    if (r.isNotEmpty && !_requirements.contains(r)) {
      setState(() {
        _requirements.add(r);
        _reqCtrl.clear();
      });
    }
  }

  void _navigateToRegistration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Registration Required',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You need to register as a recruiter first. Your job data will be saved and posted automatically after registration.',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              // Navigate to auth screen with recruiter register tab
              // Use pushReplacement to replace JobPostScreen with AuthScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(
                    userType: 'recruiter',
                    authType: 'register',
                  ),
                ),
              );
            },
            child: Text('Go to Registration'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _publishJob(Theme.of(context));
    }
  }

  void _publishJob(ThemeData theme) async {
    setState(() => _isLoading = true);

    // Shared field values — computed once and reused below
    final companyName = _companyNameCtrl.text.trim().isEmpty
        ? 'Company Name'
        : _companyNameCtrl.text.trim();
    final companyUrl = _companyUrlCtrl.text.trim().isEmpty
        ? null
        : (_companyUrlCtrl.text.trim().startsWith('http')
              ? _companyUrlCtrl.text.trim()
              : 'https://${_companyUrlCtrl.text.trim()}');
    final designation = _titleCtrl.text.trim().isEmpty
        ? 'Job Title'
        : _titleCtrl.text.trim();
    final ctc = '$_selectedSalaryMin-$_selectedSalaryMax LPA';
    final location = _locationCtrl.text.trim().isEmpty
        ? 'Location'
        : _locationCtrl.text.trim();

    // Debug logging
    print('\n========== JOB PUBLISH DEBUG ==========');
    print('Company Name: $companyName');
    print('Designation: $designation');
    print('CTC: $ctc');
    print('Location: $location');
    print('Category: $_selectedCategory');
    print('Job Type: $_selectedJobType');
    print('Experience: $_selectedExperience');
    print('Logo Path: $_companyLogoPath');
    print('Skills: $_skills');
    print('Requirements: $_requirements');
    print('=======================================\n');

    try {
      final recruiter = ref.read(currentRecruiterProvider);

      // If recruiter is null, save job data temporarily and navigate to registration
      if (recruiter == null) {
        print('No recruiter found, saving job data temporarily...');

        // Prepare job data for temporary storage
        final pendingJobData = {
          'companyName': companyName,
          'companyUrl': companyUrl,
          'designation': designation,
          'ctc': ctc,
          'location': location,
          'category': _selectedCategory,
          'description': _descCtrl.text,
          'requirements': _requirements,
          'skillsRequired': _skills,
          'perksAndBenefits': _perks,
          'experienceRequired': _selectedExperience,
          'jobType': _selectedJobType,
          'isActive': _isActive,
          'isUrgentHiring': _isUrgentHiring,
          'companyLogoPath': _companyLogoPath,
        };

        // Save to pending job service
        await PendingJobService().savePendingJob(pendingJobData);

        setState(() => _isLoading = false);

        // Navigate to auth screen with registration tab
        _navigateToRegistration();
        return;
      }

      print('Recruiter found: ${recruiter.id}');

      if (widget.job != null) {
        // Update existing job
        print('Updating existing job ID: ${widget.job!.id}');

        // Determine what to send for logo
        String? logoToSend;
        if (_companyLogoPath != null && _companyLogoPath!.isNotEmpty) {
          // If it's a local file path (new image selected), pass as companyLogoPath
          print('New logo selected, will upload via FormData');
          await ref
              .read(jobsStateProvider.notifier)
              .updateJob(
                widget.job!.id.toString(),
                companyName: companyName,
                companyUrl: companyUrl,
                designation: designation,
                ctc: ctc,
                location: location,
                category: _selectedCategory,
                description: _descCtrl.text,
                requirements: _requirements,
                skillsRequired: _skills,
                perksAndBenefits: _perks,
                experienceRequired: _selectedExperience,
                jobType: _selectedJobType,
                isActive: _isActive,
                isUrgentHiring: _isUrgentHiring,
                companyLogoPath:
                    _companyLogoPath, // Pass local file path for upload
              );
        } else {
          // No new logo selected, keep existing or null
          print('No new logo selected');
          await ref
              .read(jobsStateProvider.notifier)
              .updateJob(
                widget.job!.id.toString(),
                companyName: companyName,
                companyUrl: companyUrl,
                designation: designation,
                ctc: ctc,
                location: location,
                category: _selectedCategory,
                description: _descCtrl.text,
                requirements: _requirements,
                skillsRequired: _skills,
                perksAndBenefits: _perks,
                experienceRequired: _selectedExperience,
                jobType: _selectedJobType,
                isActive: _isActive,
                isUrgentHiring: _isUrgentHiring,
                companyLogoUrl: null, // Don't change existing logo
              );
        }
      } else {
        // Create new job - pass logo file path for upload
        print('Creating new job...');
        await ref
            .read(jobsStateProvider.notifier)
            .createJob(
              companyName: companyName,
              companyUrl: companyUrl,
              designation: designation,
              ctc: ctc,
              location: location,
              category: _selectedCategory,
              description: _descCtrl.text,
              requirements: _requirements,
              skillsRequired: _skills,
              perksAndBenefits: _perks,
              experienceRequired: _selectedExperience,
              jobType: _selectedJobType,
              isActive: _isActive,
              isUrgentHiring: _isUrgentHiring,
              companyLogoPath:
                  _companyLogoPath, // Pass local file path for upload
            );
      }

      setState(() => _isLoading = false);

      // Show success feedback
      AppScaffoldFeedback.show(
        context,
        message: widget.job != null
            ? 'Job updated successfully!'
            : 'Job published successfully!',
        type: ResponseType.success,
      );

      // Show success dialog after a brief delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showSuccessDialog(theme);
        }
      });
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      print('ERROR in _publishJob: $e');
      print('Stack trace: $stackTrace');
      AppScaffoldFeedback.show(
        context,
        message:
            'Failed to ${widget.job != null ? 'update' : 'publish'} job: $e',
        type: ResponseType.error,
      );
    }
  }

  void _showSuccessDialog(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1714);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/successful.gif',
                width: 80.w,
                height: 80.w,
              ),
              Text(
                widget.job != null ? 'Job Updated!' : 'Job Published!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '"${_titleCtrl.text}" has been ${widget.job != null ? 'updated' : 'published'} successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: textColor.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                    textStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    // Navigator.pop(ctx);
                    // if (Navigator.of(context).canPop())
                    //   Navigator.of(context).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecruiterMainScreen(index: 1),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text(
                    widget.job != null ? 'View Job' : 'View Listings',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Sub-Widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String step, title, subtitle;
  final Color textColor, labelColor, accentColor;
  const _SectionHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.labelColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11.sp, color: labelColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color bg, border;
  const _Card({required this.child, required this.bg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: color);
}

class _FieldGroup extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Widget child;
  final bool optional;

  const _FieldGroup({
    required this.label,
    required this.labelColor,
    required this.child,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.3,
              ),
            ),
            if (optional) ...[
              SizedBox(width: 5.w),
              Text(
                'Optional',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: labelColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final int minLines;
  final int maxLines;
  final Color textColor, hintColor, borderColor, accentColor, subtleFill;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.accentColor,
    required this.subtleFill,
    this.keyboardType,
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _focused = false;

  // @override
  // void initState() {
  //   super.initState();
  //   widget.focusNode?.addListener(() {
  //     if (mounted) setState(() => _focused = widget.focusNode!.hasFocus);
  //   });
  // }
  @override
  void initState() {
    super.initState();

    widget.focusNode?.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _focused = widget.focusNode!.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _focused
            ? widget.accentColor.withValues(alpha: 0.04)
            : widget.subtleFill,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: _focused ? widget.accentColor : widget.borderColor,
          width: _focused ? 1.5 : 1.0,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enableInteractiveSelection: true,
        selectionControls: MaterialTextSelectionControls(),
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        style: TextStyle(fontSize: 14.sp, color: widget.textColor, height: 1.4),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(fontSize: 13.sp, color: widget.hintColor),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: 17.sp, color: widget.hintColor)
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: widget.minLines > 1 ? 14.h : 12.h,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;
  final Color textColor, hintColor, borderColor, accentColor, subtleFill;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.accentColor,
    required this.subtleFill,
  });

  @override
  Widget build(BuildContext context) {
    final validated = (value != null && items.contains(value)) ? value : null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: subtleFill,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validated,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 13.sp, color: hintColor),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: hintColor,
            size: 20.sp,
          ),
          style: TextStyle(fontSize: 14.sp, color: textColor),
          borderRadius: BorderRadius.circular(12.r),
          onChanged: onChanged,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final Map<String, IconData> icons;
  final ValueChanged<String> onChanged;
  final Color accentColor, textColor, labelColor, borderColor, subtleFill;

  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.icons,
    required this.onChanged,
    required this.accentColor,
    required this.textColor,
    required this.labelColor,
    required this.borderColor,
    required this.subtleFill,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: categories.map((cat) {
        final isSelected = cat == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: cat != categories.last ? 8.w : 0),
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : subtleFill,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected ? accentColor : borderColor,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[cat] ?? Icons.work_outline,
                    size: 18.sp,
                    color: isSelected ? Colors.white : labelColor,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : labelColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChipInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final VoidCallback onAdd;
  final List<String> chips;
  final ValueChanged<String> onRemoveChip;
  final Color accentColor, textColor, hintColor, borderColor, subtleFill;

  const _ChipInputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.onAdd,
    required this.chips,
    required this.onRemoveChip,
    required this.accentColor,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.subtleFill,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: subtleFill,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: Icon(prefixIcon, size: 17.sp, color: hintColor),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                  style: TextStyle(fontSize: 14.sp, color: textColor),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(fontSize: 13.sp, color: hintColor),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 12.h,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10.r),
                    bottomRight: Radius.circular(10.r),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 18.sp,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (chips.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: chips
                .map(
                  (chip) => _Chip(
                    label: chip,
                    onRemove: () => onRemoveChip(chip),
                    accentColor: accentColor,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color accentColor;

  const _Chip({
    required this.label,
    required this.onRemove,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          SizedBox(width: 5.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 12.sp,
              color: accentColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor, textColor, labelColor, subtleFill;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    required this.textColor,
    required this.labelColor,
    required this.subtleFill,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: value ? accentColor.withValues(alpha: 0.1) : subtleFill,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              size: 17.sp,
              color: value ? accentColor : labelColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.sp, color: labelColor),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}

class _PerksGrid extends StatelessWidget {
  final List<String> options, selected;
  final ValueChanged<String> onToggle;
  final Color accentColor, textColor, labelColor, borderColor, subtleFill;

  const _PerksGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.accentColor,
    required this.textColor,
    required this.labelColor,
    required this.borderColor,
    required this.subtleFill,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((perk) {
        final isSelected = selected.contains(perk);
        return GestureDetector(
          onTap: () => onToggle(perk),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : subtleFill,
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: isSelected ? accentColor : borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_rounded, size: 12.sp, color: Colors.white),
                  SizedBox(width: 4.w),
                ],
                Text(
                  perk,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : labelColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LogoUploadTile extends StatelessWidget {
  final String? logoPath;
  final String? existingLogoUrl;
  final VoidCallback onTap, onRemove;
  final Color accentColor, textColor, labelColor, borderColor, subtleFill;

  const _LogoUploadTile({
    required this.logoPath,
    required this.existingLogoUrl,
    required this.onTap,
    required this.onRemove,
    required this.accentColor,
    required this.textColor,
    required this.labelColor,
    required this.borderColor,
    required this.subtleFill,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath != null || existingLogoUrl != null;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          // Preview / placeholder
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: subtleFill,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasLogo
                  ? (logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            File(logoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: labelColor,
                            ),
                          ),
                        )
                      : (existingLogoUrl != null
                          ? ShimmerImage(
                              imageUrl: existingLogoUrl!,
                              width: 60.w,
                              height: 60.w,
                              borderRadius: 8.r,
                              errorWidget: Icon(
                                Icons.broken_image_outlined,
                                color: labelColor,
                              ),
                            )
                          : Icon(
                              Icons.add_photo_alternate_outlined,
                              color: labelColor,
                              size: 22.sp,
                            )))
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      color: labelColor,
                      size: 22.sp,
                    ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLogo ? 'Company Logo' : 'Upload Company Logo',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  hasLogo ? 'Tap to change' : 'PNG or JPG • Optional',
                  style: TextStyle(fontSize: 11.sp, color: labelColor),
                ),
              ],
            ),
          ),
          if (logoPath != null)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: subtleFill,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 15.sp,
                  color: labelColor,
                ),
              ),
            )
          else if (!hasLogo)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Browse',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading, isEdit;
  final VoidCallback onTap;
  final Color accentColor;

  const _SubmitButton({
    required this.isLoading,
    required this.isEdit,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
          padding: EdgeInsets.symmetric(vertical: 15.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEdit ? Icons.save_outlined : Icons.send_rounded,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(isEdit ? 'Save Changes' : 'Publish Job'),
                ],
              ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg, iconColor;
  final double size;

  const _CircleIconBtn({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.iconColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: size, color: iconColor),
      ),
    );
  }
}