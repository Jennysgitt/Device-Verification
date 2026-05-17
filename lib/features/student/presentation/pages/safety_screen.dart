import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lightmode/core/theme/app_colors.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus Safety',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency resources and safety information.',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          _buildEmergencyButton(context),
          const SizedBox(height: 32),
          Text(
            'Quick Resources',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildResourceItem('Campus Security Hoteline', 'Call: +1 (555) 123-4567', Icons.phone_callback),
          _buildResourceItem('Student Health Center', 'Direct line for emergencies', Icons.medical_services_outlined),
          _buildResourceItem('Safe Walk Program', 'Request a security escort', Icons.directions_walk),
          _buildResourceItem('Crime Reporting', 'Submit an anonymous tip', Icons.assignment_late_outlined),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sos, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Emergency SOS',
            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to broadcast your location to campus security immediately.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(String title, String sub, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(sub, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.outline),
        ],
      ),
    );
  }
}
