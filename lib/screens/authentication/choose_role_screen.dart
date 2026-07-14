import 'package:airigo_jobportal/screens/authentication/auth_screen.dart';
import 'package:airigo_jobportal/screens/recruiter/job_post_screen.dart';
import 'package:flutter/material.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    final userType = _selectedIndex == 0 ? "jobseeker" : "recruiter";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(userType: userType, authType: 'login'),
      ),
    );
  }

  void _navigateToSignupOrPostJob() {
    final userType = _selectedIndex == 0 ? "jobseeker" : "recruiter";

    if (_selectedIndex == 0) {
      // For jobseeker, navigate to signup
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(userType: userType, authType: 'register'),
        ),
      );
    } else {
      // For recruiter, navigate to job details screen first
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const JobPostScreen(isBackButton: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final colorScheme = Theme.of(context).colorScheme;
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: _selectedIndex == 1
                ? Image.asset(
                    "assets/images/Recruiter.png",
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.5),
                  )
                : Image.asset(
                    "assets/images/Jobseeker.png",
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.5),
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),

          // ── Decorative blobs ─────────────────────────────────────────────
          Positioned(
            top: -h * 0.08,
            left: -w * 0.2,
            child: Container(
              width: w * 0.65,
              height: w * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.18),
                    colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: h * 0.05,
            left: -w * 0.25,
            child: Container(
              width: w * 0.6,
              height: w * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.tertiary.withValues(alpha: 0.12),
                    colorScheme.tertiary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // SizedBox(height: h * 0.07),
                      const Spacer(),
                      Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: w * 0.075,
                          fontWeight: FontWeight.w800,
                          // color: colorScheme.onSurface,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: h * 0.018),

                      // ── Role selector ─────────────────────────────────
                      Text(
                        "Continue as...",
                        style: TextStyle(
                          fontSize: w * 0.038,
                          fontWeight: FontWeight.w500,
                          // color: colorScheme.onSurface.withValues(alpha: 0.55),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: h * 0.018),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(w * 0.04),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            _RoleTab(
                              label: "Jobseeker",
                              icon: Icons.person_search_rounded,
                              isSelected: _selectedIndex == 0,
                              onTap: () {
                                setState(() => _selectedIndex = 0);
                              },
                              colorScheme: colorScheme,
                              width: w,
                            ),
                            _RoleTab(
                              label: "Recruiter",
                              icon: Icons.business,
                              isSelected: _selectedIndex == 1,
                              onTap: () {
                                setState(() => _selectedIndex = 1);
                              },
                              colorScheme: colorScheme,
                              width: w,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: h * 0.025),

                      // ── Login Button ──────────────────────────────────
                      _ActionButton(
                        label: "Log In",
                        onTap: _navigateToLogin,
                        isPrimary: true,
                        colorScheme: colorScheme,
                        width: w,
                        height: h,
                      ),
                      SizedBox(height: h * 0.018),

                      // ── Sign Up or Post Job Button ────────────────────────────────
                      _ActionButton(
                        label: _selectedIndex == 1
                            ? "Post Job"
                            : "Create Account",
                        onTap: _navigateToSignupOrPostJob,
                        isPrimary: false,
                        colorScheme: colorScheme,
                        width: w,
                        height: h,
                      ),

                      // const Spacer(),
                      SizedBox(height: h * 0.07),

                      // ── Footer ────────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.only(bottom: h * 0.03),
                        child: Text(
                          "By continuing you agree to our Terms & Privacy Policy",
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Tab Widget ──────────────────────────────────────────────────────────

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final double width;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: width * 0.12,
              color: isSelected ? colorScheme.primary : Colors.white,
            ),
            SizedBox(width: width * 0.02),
            AnimatedContainer(
              // height: double.infinity,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(width * 0.032),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.w600,
                  // color: isSelected
                  //     ? colorScheme.onPrimary
                  //     : colorScheme.onSurface.withValues(alpha: 0.55),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button Widget ─────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final ColorScheme colorScheme;
  final double width;
  final double height;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
    required this.colorScheme,
    required this.width,
    required this.height,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: widget.height * 0.065,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.width * 0.035),
            border: widget.isPrimary
                ? null
                : Border.all(color: Colors.white, width: 1.5),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: widget.colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.width * 0.042,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
