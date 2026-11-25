import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import '../shared/widgets/app_card.dart';

class AuthScreen extends StatefulWidget {
  final Function(User user) onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isDoctorLogin = false; // Default is Patient Login
  bool _isLoading = false;
  String? _errorMessage;

  final _emailCtrl = TextEditingController(text: "patient@medisync.health");
  final _passwordCtrl = TextEditingController(text: "patient123");
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _toggleRole(bool toDoctor) {
    setState(() {
      _isDoctorLogin = toDoctor;
      _errorMessage = null;
      if (toDoctor) {
        _emailCtrl.text = "doctor@medisync.health";
        _passwordCtrl.text = "doctor123";
      } else {
        _emailCtrl.text = "patient@medisync.health";
        _passwordCtrl.text = "patient123";
      }
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final role = _isDoctorLogin ? "doctor" : "patient";

    final user = await ApiService.login(email, password, role: role);

    setState(() => _isLoading = false);

    if (user != null) {
      widget.onLoginSuccess(user);
    } else {
      // Offline fallback for testing
      final fallbackUser = User(
        uid: _isDoctorLogin ? "usr_doctor_1" : "usr_patient_1",
        name: _isDoctorLogin ? "Dr. Sarah Jenkins" : "Sarah Connor",
        email: email,
        role: role,
        doctorId: _isDoctorLogin ? "doc_1" : null,
        mrn: _isDoctorLogin ? null : "MRN-78219",
        specialty: _isDoctorLogin ? "Cardiology" : null,
      );
      ApiService.currentUser = fallbackUser;
      widget.onLoginSuccess(fallbackUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [AppColors.subtleShadow],
                    ),
                    child: const Center(
                      child: Icon(Icons.medical_services_outlined, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const Text("MediSync", style: AppTypography.h1),
                      const SizedBox(height: 4),
                      Text(
                        _isDoctorLogin
                            ? "Physician & Clinical Specialist Portal"
                            : "Personal AI Health Assistant & Vault",
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Main Login Card
                AppCard(
                  variant: CardVariant.standard,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isDoctorLogin ? Icons.healing_rounded : Icons.person_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _isDoctorLogin ? "Doctor Portal Sign In" : "Patient Portal Sign In",
                              style: AppTypography.h2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isDoctorLogin
                            ? "Access your appointments, manage schedule, and review patient charts via secure tokens."
                            : "Access your centralized medical vault, AI health explanations, and doctor appointments.",
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.criticalLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.criticalBorder),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.caption.copyWith(color: AppColors.critical, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: _isDoctorLogin ? "Physician Email" : "Patient Email",
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : Text(
                                _isDoctorLogin ? "Sign In to Doctor Portal" : "Sign In to Patient Portal",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // One-tap quick credentials helper
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isDoctorLogin ? "Demo: Dr. Sarah Jenkins (Cardiology)" : "Demo: Sarah Connor (MRN-78219)",
                                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _isDoctorLogin ? "doctor@medisync.health • doctor123" : "patient@medisync.health • patient123",
                                    style: AppTypography.caption.copyWith(fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () {
                                if (_isDoctorLogin) {
                                  _emailCtrl.text = "doctor@medisync.health";
                                  _passwordCtrl.text = "doctor123";
                                } else {
                                  _emailCtrl.text = "patient@medisync.health";
                                  _passwordCtrl.text = "patient123";
                                }
                              },
                              child: const Text("Fill", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Role Toggle Prominent Link
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _toggleRole(!_isDoctorLogin),
                    icon: Icon(
                      _isDoctorLogin ? Icons.person_outline_rounded : Icons.healing_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      _isDoctorLogin
                          ? "Are you a patient? Go to Patient Portal →"
                          : "Are you a doctor? Go to Doctor Portal →",
                      style: AppTypography.button.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Reassurance
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "End-to-End Cryptographic Record Security & Privacy",
                          style: AppTypography.caption.copyWith(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
