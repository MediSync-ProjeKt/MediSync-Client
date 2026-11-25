import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'models/report_model.dart';
import 'screens/auth_screen.dart';
import 'screens/patient_portal_screen.dart';
import 'screens/doctor_portal_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MediSyncApp());
}

class MediSyncApp extends StatelessWidget {
  const MediSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediSync — Clinical Healthcare & AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

/// Auth-gated shell: shows AuthScreen when logged out,
/// routes to PatientPortalScreen or DoctorPortalScreen after login.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  User? _currentUser;

  void _onLoginSuccess(User user) {
    setState(() => _currentUser = user);
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
      ApiService.currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Not logged in → show auth screen
    if (_currentUser == null) {
      return AuthScreen(onLoginSuccess: _onLoginSuccess);
    }

    // Doctor portal
    if (_currentUser!.role == 'doctor') {
      return _AppFrame(
        user: _currentUser!,
        onLogout: _onLogout,
        child: DoctorPortalScreen(onLogout: _onLogout),
      );
    }

    // Default: Patient portal
    return _AppFrame(
      user: _currentUser!,
      onLogout: _onLogout,
      child: PatientPortalScreen(
        onLogout: _onLogout,
      ),
    );
  }
}

/// Shared app chrome: clinical top bar + user identity + logout.
class _AppFrame extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;
  final Widget child;

  const _AppFrame({
    required this.user,
    required this.onLogout,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDoctor = user.role == 'doctor';
    final subtitle = isDoctor
        ? 'Physician & Clinical Specialist Portal'
        : 'Personal AI Health Assistant & Vault';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Brand mark
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.medical_services_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MediSync', style: AppTypography.h3),
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User identity pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDoctor ? Icons.healing_rounded : Icons.person_outline_rounded,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.name,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Logout button
                  Tooltip(
                    message: 'Sign out',
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onLogout,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: child,
        ),
      ),
    );
  }
}
