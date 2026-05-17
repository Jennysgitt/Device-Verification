import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lightmode/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/backend/providers/auth_provider.dart';
import '../../../../core/backend/services/notification_service.dart';
import '../../../../core/backend/services/supabase_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _isSending = false;

  Future<void> _alertAuthorities(BuildContext context, {bool flagAsStolen = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) return;

    setState(() => _isSending = true);

    try {
      // 1. If this is a theft report, mark all user devices as stolen in the DB
      if (flagAsStolen) {
        await supabase.flagUserDevicesAsStolen(user.id);
      }

      // 2. Broadcast emergency notification to security personnel
      await notificationService.sendNotification(
        userId: user.id,
        title: flagAsStolen ? '🚨 STOLEN DEVICE REPORTED' : '🚨 EMERGENCY SOS',
        message: flagAsStolen
            ? 'Student ${user.fullName} has reported their device(s) as stolen. All hardware flagged in registry.'
            : 'Student ${user.fullName} has triggered an emergency signal. Assistance requested immediately.',
        priority: 'emergency',
        category: 'security_alert',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(flagAsStolen
                ? 'Devices flagged as STOLEN. Security HQ notified.'
                : 'SOS Signal Broadcasted to Security HQ'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send SOS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emergency, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Text(
                  'EMERGENCY SOS ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Emergency & SOS',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Immediate assistance for stolen hardware or campus security threats.',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          if (_isSending)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.error),
            )),
          _buildSOSCard(
            'Report Stolen Device',
            'Immediately flag your hardware and alert campus security.',
            Icons.report_problem,
            AppColors.error,
            () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Report Stolen?'),
                  content: const Text('This will flag your registered devices as stolen in the central registry and alert all checkpoint officers.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _alertAuthorities(context, flagAsStolen: true);
                      }, 
                      child: const Text('REPORT', style: TextStyle(color: AppColors.error))
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSOSCard(
            'Security Hotlink',
            'Direct line to the Campus Security Command Center.',
            Icons.phone_in_talk,
            AppColors.primary,
            () => _makeCall('0800732873'),
          ),
          const SizedBox(height: 16),
          _buildSOSCard(
            'Alert Authorities',
            'Broadcast an emergency signal to nearby security posts.',
            Icons.vibration,
            AppColors.secondary,
            () => _alertAuthorities(context),
          ),
          const SizedBox(height: 32),
         ],
      ),
    );
  }

  Widget _buildSOSCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
