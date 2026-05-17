import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lightmode/core/theme/app_colors.dart';
import 'package:lightmode/core/backend/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String selectedRole = 'Student';
  bool obscurePassword = true;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      _redirect(authProvider.currentUser!.role);
    }
  }

  void _redirect(String? role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'officer') {
      Navigator.pushReplacementNamed(context, '/officer');
    } else {
      Navigator.pushReplacementNamed(context, '/student');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  try {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      throw Exception('Please enter your email/ID and password.');
    }

    if (selectedRole == 'Student' && !input.contains('@')) {
      await authProvider.signInWithStudentId(input, password);
    } else {
      await authProvider.signInWithEmail(input, password);
    }

    if (!mounted) return;

    final user = authProvider.currentUser;

    if (user == null) {
      throw Exception('Unable to load user profile.');
    }

    final selectedRoleLower = selectedRole.toLowerCase();
    final actualRoleLower = user.role.toLowerCase();

    if (selectedRoleLower != actualRoleLower) {
      await authProvider.signOut();

      throw Exception(
        'You selected $selectedRole portal, but this account belongs to ${user.role}. Please use the correct portal.',
      );
    }

    _redirect(user.role);
  } catch (e) {
    if (mounted) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.split('Exception: ')[1];
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: 900,
            constraints: const BoxConstraints(maxWidth: 1000),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Side: Branding (Visible only on desktop/web/tablet)
                  if (MediaQuery.of(context).size.width > 768)
                    Expanded(
                      flex: 5,
                      child: _buildBrandingSide(),
                    ),
                  
                  // Right Side: Login Form
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mobile Logo
                          if (MediaQuery.of(context).size.width <= 768)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 32),
                                child: _buildLogo(isDark: true),
                              ),
                            ),
                          
                          Text(
                            'Sign In',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your credentials to access the secure portal.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          _buildRoleSelector(),
                          const SizedBox(height: 32),
                          
                          _buildLoginForm(),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
        ),
      ),
    );
  }

  Widget _buildBrandingSide() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
      ),
      child: Stack(
        children: [
          // Background Blur Pattern
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ).animate().shimmer(duration: 3.seconds),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogo(isDark: true),
              const Spacer(),
              Text(
                'Enterprise-Grade\nSecurity Access',
                style: GoogleFonts.manrope(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Advanced authentication and threat prevention protocols engineered for campus and corporate safety.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: AppColors.primaryFixedDim,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildBrandingBadge(Icons.enhanced_encryption_outlined, 'End-to-End Encrypted'),
                  const SizedBox(width: 16),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primaryFixedDim, shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  _buildBrandingBadge(Icons.shield_outlined, 'SOC2 Compliant'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({required bool isDark}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'SG',
            style: GoogleFonts.manrope(
              color: isDark ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'SecureGate AI',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryFixedDim),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryFixedDim,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: ['Student', 'Officer', 'Admin'].map((role) {
          final isSelected = selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedRole = role),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'University ID or Email',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.outlineVariant),
            hintText: 'e.g. 12345678 or name@university.edu',
            hintStyle: GoogleFonts.inter(color: AppColors.outlineVariant, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.outlineVariant),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.outlineVariant,
              ),
              onPressed: () => setState(() => obscurePassword = !obscurePassword),
            ),
            hintText: '••••••••',
            hintStyle: GoogleFonts.inter(color: AppColors.outlineVariant, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: rememberMe,
                onChanged: (v) => setState(() => rememberMe = v ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember this device for 30 days',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => ElevatedButton.icon(
            onPressed: auth.isLoading ? null : _handleSignIn,
            icon: auth.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.login, size: 20),
            label: Text(auth.isLoading ? 'Authenticating...' : 'Secure Sign In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                'Register',
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
