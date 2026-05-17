import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lightmode/core/backend/providers/auth_provider.dart';
import 'package:lightmode/core/backend/models/user_model.dart';
import 'package:lightmode/features/student/presentation/pages/profile_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/backend/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:lightmode/core/backend/providers/notification_provider.dart';
import 'package:lightmode/core/common/widgets/notification_hub.dart';


class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  int _currentIndex = 0;
  Future<Map<String, dynamic>>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  void _fetchDashboardData() {
    setState(() {
      _dashboardData = Provider.of<SupabaseService>(context, listen: false).getOfficerDashboardData();
    });
  }

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
                if (isDesktop) _buildDesktopHeader(context, user),
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
        return RefreshIndicator(
          onRefresh: () async => _fetchDashboardData(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _dashboardData,
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    final stats = data?['stats'] as Map<String, int>?;
                    final recentLogs = data?['recentActivity'] as List<Map<String, dynamic>>?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShiftOverview(context, isDesktop),
                        const SizedBox(height: 24),
                        _buildStatsRow(context, isDesktop, stats),
                        const SizedBox(height: 24),
                        _buildActivityLog(context, recentLogs),
                        const SizedBox(height: 64),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      case 1:
        // Placeholder for Scan - In a real app this would navigate to a scanner page
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('SCANNER MODULE', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/officer/verify'),
                child: const Text('Launch Scanner'),
              ),
            ],
          ),
        );
      case 2:
        return const NotificationHub();
      case 3:
        return const ProfileScreen();
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
                Text(
                  'SecureGate Staff',
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
          _buildSidebarItem(context, Icons.grid_view_outlined, 'Home', index: 0),
          _buildSidebarItem(context, Icons.qr_code_scanner, 'Scan Hardware', index: 1),
          _buildSidebarItem(context, Icons.notifications_none, 'Security Alerts', index: 2),
          _buildSidebarItem(context, Icons.person_outline, 'Profile', index: 3),
          const Spacer(),
          _buildSidebarProfile(user),
        ],
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
            child: Text((user?.fullName ?? 'O').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.fullName ?? 'Officer Name', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('Security Personnel', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
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

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.security, color: AppColors.primary, size: 28),
          Text(
            'SECUREGATE STAFF',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              letterSpacing: 1.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, UserModel? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            'Security Officer Dashboard',
            style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const Spacer(),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) => IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
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
              onPressed: () => setState(() => _currentIndex = 2),
            ),
          ),
          const SizedBox(width: 16),
          _buildProfileAvatar((user?.fullName ?? 'O').substring(0, 1).toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String initials) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(99)),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildShiftOverview(BuildContext context, bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 8, child: _buildAssignmentCard()),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _buildLaunchScannerAction(context)),
        ],
      );
    } else {
      return Column(
        children: [
          // _buildAssignmentCard(),
          // const SizedBox(height: 16),
          _buildLaunchScannerAction(context),
        ],
      );
    }
  }

  Widget _buildAssignmentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT ASSIGNMENT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text('Main Gate', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('SHIFT REMAINING', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('04:22', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.secondaryContainer.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.secondaryContainer.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'System Status: All sensors operational. Secure network active.',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchScannerAction(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primaryContainer.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/officer/verify'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            const SizedBox(height: 16),
            Text('Launch Scanner', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('TAP TO VERIFY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8), letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDesktop, Map<String, int>? stats) {
    final scans = stats?['scans']?.toString() ?? '...';
    final flagged = stats?['flagged']?.toString() ?? '...';

    return LayoutBuilder(builder: (context, constraints) {
      if (isDesktop) {
        return Row(
          children: [
            Expanded(child: _buildStatCard(Icons.how_to_reg, scans, 'Scans Today', AppColors.primary)),
            const SizedBox(width: 24),
            Expanded(child: _buildStatCard(Icons.flag, flagged, 'System Flags', AppColors.error)),
            const SizedBox(width: 24),
            Expanded(child: _buildStatCard(Icons.notifications_active, '0', 'Active Alerts', AppColors.secondary)),
          ],
        );
      } else {
        return Column(
          children: [
            _buildStatCard(Icons.how_to_reg, scans, 'Scans Today', AppColors.primary),
            const SizedBox(height: 16),
            _buildStatCard(Icons.flag, flagged, 'System Flags', AppColors.error),
            const SizedBox(height: 16),
            _buildStatCard(Icons.notifications_active, '0', 'Active Alerts', AppColors.secondary),
          ],
        );
      }
    });
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: (color == AppColors.primary ? AppColors.surfaceContainerHigh : color.withOpacity(0.1)), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLog(BuildContext context, List<Map<String, dynamic>>? logs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.outline, size: 24),
                    const SizedBox(width: 12),
                    Text('Recent Activity Log', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 2), // Go to Alerts/Logs
                  child: Text('View All', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          if (logs == null || logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('No recent activity recorded.', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant))),
            )
          else
            ...logs.map((log) {
              final device = log['devices'] as Map<String, dynamic>?;
              final user = device?['users'] as Map<String, dynamic>?;
              final status = log['status'] as String;
              final isVerified = status == 'verified';
              final time = DateTime.parse(log['created_at']);
              
              return Column(
                children: [
                  _buildLogItem(
                    isVerified ? 'Verification Successful' : 'Security Flag: ID Mismatch',
                    '${user?['full_name'] ?? 'Unknown'} • ${device?['brand'] ?? 'Device'} • ${log['entry_type'].toString().toUpperCase()}',
                    _formatTimeAgo(time),
                    isVerified ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    isVerified ? AppColors.secondary : AppColors.error,
                  ),
                  if (log != logs.last) const Divider(height: 1, color: AppColors.surfaceVariant),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLogItem(String title, String desc, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Text(time, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
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
          _buildBottomNavItem(Icons.grid_view_outlined, 'Home', index: 0),
          _buildBottomNavItem(Icons.qr_code_scanner, 'Scan', index: 1),
          _buildBottomNavItem(Icons.notifications_none, 'Alerts', index: 2),
          _buildBottomNavItem(Icons.person_outline, 'Profile', index: 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, {required int index}) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
