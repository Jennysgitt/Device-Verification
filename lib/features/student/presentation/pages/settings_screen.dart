import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lightmode/core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your security preferences and app behavior.',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          _buildSettingsGroup('Security', [
            _buildSettingsItem('Change Password', Icons.lock_outline, onTap: () {}),
            _buildSettingsItem('Biometric Login', Icons.fingerprint, isSwitch: true, value: true),
            _buildSettingsItem('Two-Factor Auth', Icons.security, isSwitch: true, value: false),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup('Notifications', [
            _buildSettingsItem('Push Notifications', Icons.notifications_none, isSwitch: true, value: true),
            _buildSettingsItem('Email Alerts', Icons.email_outlined, isSwitch: true, value: true),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup('System', [
            _buildSettingsItem('Dark Mode', Icons.dark_mode_outlined, isSwitch: true, value: false),
            _buildSettingsItem('About SecureGate AI', Icons.info_outline),
            _buildSettingsItem('Privacy Policy', Icons.privacy_tip_outlined),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(String label, IconData icon, {bool isSwitch = false, bool value = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          if (isSwitch)
            Switch(value: value, onChanged: (v) {}, activeColor: AppColors.primary)
          else
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.outline),
        ],
      ),
    );
  }
}
