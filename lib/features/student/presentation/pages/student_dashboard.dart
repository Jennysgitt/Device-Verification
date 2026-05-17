import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lightmode/core/backend/providers/auth_provider.dart';
import 'package:lightmode/core/backend/models/user_model.dart';
import 'package:lightmode/features/student/presentation/pages/devices_screen.dart';
import 'package:lightmode/core/backend/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:lightmode/features/student/presentation/pages/profile_screen.dart';
import 'package:lightmode/features/student/presentation/pages/settings_screen.dart';
import 'package:lightmode/features/student/presentation/pages/support_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lightmode/core/backend/providers/notification_provider.dart';
import 'package:lightmode/core/common/widgets/notification_hub.dart';


class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, user),
          Expanded(
            child: Column(
              children: [
                if (!isDesktop) _buildMobileHeader(context),
                Expanded(
                  child: _buildBody(isDesktop, user),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop ? _buildBottomNav(context) : null,
    );
  }

  Widget _buildBody(bool isDesktop, UserModel? user) {
    switch (_currentIndex) {
      case 0:
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48.0 : 16.0,
            vertical: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(context, isDesktop, user),
              const SizedBox(height: 32),
              _buildBentoGrid(context, isDesktop),
              const SizedBox(height: 32),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildRecentActivity(context),
              const SizedBox(height: 64),
            ],
          ),
        );
      case 1:
        return const DevicesScreen();
      case 2:
        return const SupportScreen(); // SOS moved to 2
      case 3:
        return const ProfileScreen(); // Profile moved to 3
      case 4:
        return const SettingsScreen();
      case 5:
        return const NotificationHub(); // Alerts at 5
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSidebar(BuildContext context, UserModel? user) {
    return Container(
      width: 280,
      color: AppColors.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.security, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'SecureGate AI',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSidebarItem(context, Icons.analytics, 'Intelligence', index: 0),
          _buildSidebarItem(context, Icons.fact_check_outlined, 'Device Registry', index: 1),
          _buildSidebarItem(context, Icons.person_outline, 'Profile', index: 2),
          _buildSidebarItem(context, Icons.settings_outlined, 'Settings', index: 3),
          _buildSidebarItem(context, Icons.sos, 'Emergency SOS', index: 4),
          const Spacer(),
          _buildSidebarProfile(user),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String label, {required int index}) {
    final isActive = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
          size: 20,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
          ),
        ),
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSidebarProfile(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text((user?.fullName ?? 'S').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.fullName ?? 'Student Name', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(user?.role.toUpperCase() ?? 'STUDENT', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.security, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'SecureGate AI',
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const Spacer(),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) => IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
                  if (provider.hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => setState(() => _currentIndex = 5),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(Icons.person_outline, size: 20, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, bool isDesktop, UserModel? user) {
    final firstName = user?.fullName?.split(' ').first ?? 'Student';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $firstName',
          style: GoogleFonts.manrope(
            fontSize: isDesktop ? 32 : 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your campus security overview for today.',
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(BuildContext context, bool isDesktop) {
    final devices = Provider.of<AuthProvider>(context).devices;
    final deviceCount = devices.length.toString();
    
    return LayoutBuilder(builder: (context, constraints) {
      if (isDesktop) {
        return Row(
          children: [
            Expanded(
              child: _buildCountCard(
                'Your Devices',
                deviceCount,
                'All devices verified and active.',
                AppColors.primary,
                Icons.devices,
              ),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            _buildCountCard(
              'Your Devices',
              deviceCount,
              'All devices verified and active.',
              AppColors.primary,
              Icons.devices,
            ),
          ],
        );
      }
    });
  }

  Widget _buildCountCard(String title, String count, String subtext, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(count, style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(subtext, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          return Row(
            children: [
              _buildActionItem(Icons.qr_code_2, 'My QR Code', AppColors.primary, onTap: () {
                _showQrCodeDialog(context);
              }),
              const SizedBox(width: 16),
              _buildActionItem(Icons.add_to_home_screen, 'Register New Device', AppColors.primary, onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
              }),
              const SizedBox(width: 16),
              _buildActionItem(Icons.sos, 'Emergency Support', AppColors.error, isCritical: true, onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, {bool isCritical = false, VoidCallback? onTap}) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isCritical ? AppColors.error.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCritical ? AppColors.error.withOpacity(0.2) : AppColors.surfaceVariant.withOpacity(0.5)),
        ),
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isCritical ? AppColors.error : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isCritical ? Colors.white : color, size: 24),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isCritical ? AppColors.error : AppColors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final supabase = Provider.of<SupabaseService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase.getStudentDashboardActivity(userId: user?.id ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, color: AppColors.surfaceVariant, size: 48),
                        const SizedBox(height: 16),
                        Text('No recent activity found', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length > 5 ? 5 : activities.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.surfaceVariant),
                itemBuilder: (context, index) {
                  final act = activities[index];
                  final isRegistration = act['type'] == 'registration';
                  final status = act['status'] as String;
                  final createdAt = DateTime.parse(act['created_at'] as String);
                  final timeStr = DateFormat('hh:mm a').format(createdAt);
                  final dateStr = DateFormat('MMM dd').format(createdAt);
                  
                  final isSuccess = status == 'success' || status == 'granted' || status == 'verified';
                  final icon = isRegistration ? Icons.add_to_home_screen : (isSuccess ? Icons.how_to_reg : Icons.gpp_bad);
                  final color = isSuccess ? AppColors.secondary : AppColors.error;
                  final title = isRegistration ? 'New Device Registered' : (isSuccess ? 'Access Granted' : 'Access Denied');
                  final sub = '${act['brand']} ${act['model']} • ${act['location']}';

                  return _buildActivityItem(title, sub, timeStr, dateStr, icon, color);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentIndex = 1), // Takes them to Device Registry
            child: Text('View All History', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String sub, String time, String day, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(sub, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
              Text(day, style: GoogleFonts.inter(fontSize: 10, color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context) {
    final devices = Provider.of<AuthProvider>(context, listen: false).devices;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No registered devices found. Please register a device first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your Access QR', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280, // Increased height to 280 from 240
                    child: PageView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return SingleChildScrollView( // Added scrollability to prevent vertical overflow
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: QrImageView(
                                  data: device.qrCodeHash ?? device.qrCodeUrl ?? device.id,
                                  version: QrVersions.auto,
                                  size: 160.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${device.brand} ${device.model}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'S/N: ${device.serialNumber}',
                                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (devices.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        devices.length,
                        (index) => Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Swipe to see more devices', style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceVariant.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home, 'Home', index: 0),
          _buildBottomNavItem(Icons.sensors, 'Devices', index: 1),
          _buildBottomNavItem(Icons.sos, 'SOS', index: 2),
          _buildBottomNavItem(Icons.person, 'Profile', index: 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, {required int index}) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
