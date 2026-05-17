import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lightmode/core/theme/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Terms & Conditions', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Agreement',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            _buildSection(
              '1. Acceptance of Terms',
              'By creating an account on SecureGate AI, you agree to comply with all university hardware security protocols and local regulations regarding device registration and scanning.',
            ),
            _buildSection(
              '2. Data Privacy',
              'Your location data is only captured during active security scans for institutional safety audits. Hardware serial numbers are encrypted and used solely for identification within the SecureGate ecosystem.',
            ),
            _buildSection(
              '3. Asset Ownership',
              'Users are responsible for the accuracy of registered device information. Reporting a device as stolen initiates an immediate campus-wide security flag.',
            ),
            _buildSection(
              '4. Liability',
              'SecureGate AI is a verification tool. Final entry/exit decisions remain at the discretion of the security personnel on duty.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: May 2026',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }
}
