import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lightmode/core/theme/app_colors.dart';
import 'package:lightmode/core/backend/providers/auth_provider.dart';
import 'package:lightmode/features/auth/presentation/pages/terms_conditions_screen.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String selectedRole = 'student';
  bool obscurePassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('Please fill all fields');
      }

      if (!_acceptTerms) {
        throw Exception('You must accept the Terms and Conditions');
      }

      await authProvider.signUpWithEmail(
        email: email,
        password: password,
        fullName: name,
        role: selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.split('Exception: ')[1];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
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
                   if (MediaQuery.of(context).size.width > 768)
                    Expanded(
                      flex: 5,
                      child: _buildBrandingSide(),
                    ),
                  
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           if (MediaQuery.of(context).size.width <= 768)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 32),
                                child: _buildLogo(isDark: false),
                              ),
                            ),
                          
                          Text(
                            'Create Account',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join the secure campus hardware ecosystem.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          _buildRoleSelector(),
                          const SizedBox(height: 32),
                          
                          _buildRegisterForm(),
                          
                          const SizedBox(height: 48),
                          _buildFooter(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(isDark: true),
          const Spacer(),
          Text(
            'Enroll in\nSafe Access',
            style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
             'Register your university identity to begin managing and securing your hardware devices.',
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: AppColors.primaryFixedDim,
              height: 1.6,
            ),
          ),
          const Spacer(),
          _buildBrandingBadge(Icons.assignment_ind_outlined, 'Identity Verified'),
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
            style: GoogleFonts.outfit(
              color: isDark ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'SecureGate AI',
          style: GoogleFonts.outfit(
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
          style: GoogleFonts.manrope(
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
        children: ['student', 'officer'].map((role) {
          final isSelected = selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedRole = role),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  role.toUpperCase(),
                  style: GoogleFonts.manrope(
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

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Full Name'),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person_outline, color: AppColors.outlineVariant),
            hintText: 'John Doe',
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel('Email Address'),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.outlineVariant),
            hintText: 'name@university.edu',
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel('Password'),
        TextField(
          controller: _passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.outlineVariant),
            suffixIcon: IconButton(
              icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => obscurePassword = !obscurePassword),
            ),
            hintText: '••••••••',
          ),
        ),
        const SizedBox(height: 16),
        _buildTermsCheckbox(),
        const SizedBox(height: 32),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => ElevatedButton(
            onPressed: auth.isLoading ? null : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: auth.isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Account'),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: AppColors.outlineVariant,
      ),
      child: CheckboxListTile(
        value: _acceptTerms,
        onChanged: (value) => setState(() => _acceptTerms = value ?? false),
        title: Wrap(
          children: [
            Text(
              'I agree to the ',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
              ),
              child: Text(
                'Terms and Conditions',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primary,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppColors.surfaceVariant),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account? '),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
      ],
    );
  }
}
