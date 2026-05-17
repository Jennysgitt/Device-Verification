import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/backend/models/user_model.dart';
import '../../../../core/backend/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/backend/services/supabase_service.dart';
import '../../../../core/backend/services/pdf_service.dart'; // NEW
import '../../../student/presentation/pages/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHub extends StatefulWidget {
  const AdminHub({super.key});

  @override
  State<AdminHub> createState() => _AdminHubState();
}

class _AdminHubState extends State<AdminHub> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ),
    );
  }

  Widget _buildBody(bool isDesktop, UserModel? user) {
    switch (_currentIndex) {
      case 0:
        return _buildIntelligenceDashboard(isDesktop);
      case 1:
        return _buildHardwareAuditView();
      case 2:
        return _buildSystemLogsView();
      case 3:
        return const ProfileScreen();
      case 4:
        return _buildUserDirectoryView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntelligenceDashboard(bool isDesktop) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<SupabaseService>(context, listen: false).getAdminDashboardData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final data = snapshot.data;
        final stats = (data?['stats'] as Map?)?.cast<String, dynamic>() ?? {};
        final recentLogs = (data?['recentActivity'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final volume = (data?['volume'] as Map?)?.cast<String, int>() ?? {};
        final breakdown = (data?['breakdown'] as Map?)?.cast<String, int>() ?? {};

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48.0 : 16.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildTelemetryGrid(isDesktop, stats),
                const SizedBox(height: 32),
                _buildManagementTiles(isDesktop),
                const SizedBox(height: 32),
                _buildChartsSection(context, isDesktop, volume, breakdown),
                const SizedBox(height: 32),
                _buildAuditTable(context, recentLogs),
                const SizedBox(height: 64),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserDirectoryView() {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    return FutureBuilder<List<UserModel>>(
      future: supabase.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User Directory', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (user.fullName ?? 'U').substring(0, 1).toUpperCase(), 
                          style: const TextStyle(color: AppColors.primary)
                        ),
                      ),
                      title: Text(user.fullName ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email),
                      trailing: _buildRoleBadge(user.role),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = AppColors.primary;
    if (role == 'admin') color = AppColors.error;
    if (role == 'officer') color = AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTelemetryGrid(bool isDesktop, Map<String, dynamic> stats) {
    final telemetryItems = [
      _buildTelemetryCard('Total Devices', stats['totalDevices']?.toString() ?? '0', Icons.devices, AppColors.primary, 'Registered Hardware'),
      _buildTelemetryCard('Verified Today', stats['verifiedToday']?.toString() ?? '0', Icons.check_circle, AppColors.secondary, 'Institutional Success'),
      _buildTelemetryCard('Security Alerts', stats['activeAlerts']?.toString() ?? '0', Icons.security, AppColors.error, 'Critical Flags'),
      _buildTelemetryCard('Suspicious Activity', stats['suspiciousToday']?.toString() ?? '0', Icons.warning, Colors.orange, 'Awaiting Review'),
    ];

    if (isDesktop) {
      return Row(
        children: telemetryItems.map((item) => Expanded(child: Padding(
          padding: EdgeInsets.only(right: item == telemetryItems.last ? 0 : 24),
          child: item,
        ))).toList(),
      );
    } else {
      return Column(
        children: telemetryItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: item,
        )).toList(),
      );
    }
  }

  Widget _buildManagementTiles(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Management',
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        isDesktop 
          ? Row(
              children: [
                Expanded(child: _buildManagementCard(
                  'User Directory', 
                  'Manage system roles and permissions', 
                  Icons.group, 
                  AppColors.primary,
                  onTap: () => setState(() => _currentIndex = 4),
                )),
                const SizedBox(width: 24),
                Expanded(child: _buildManagementCard(
                  'Hardware Inventory', 
                  'Audit registered student devices', 
                  Icons.devices_other, 
                  AppColors.secondary,
                  onTap: () => setState(() => _currentIndex = 1),
                )),
              ],
            )
          : Column(
              children: [
                _buildManagementCard(
                  'User Directory', 
                  'Manage system roles and permissions', 
                  Icons.group, 
                  AppColors.primary,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
                const SizedBox(height: 16),
                _buildManagementCard(
                  'Hardware Inventory', 
                  'Audit registered student devices', 
                  Icons.devices_other, 
                  AppColors.secondary,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildManagementCard(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
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
                  'SecureGate Admin',
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
          _buildSidebarItem(Icons.analytics, 'Intelligence', index: 0),
          _buildSidebarItem(Icons.fact_check_outlined, 'Hardware Audit', index: 1),
          _buildSidebarItem(Icons.history, 'System Logs', index: 2),
          _buildSidebarItem(Icons.person_outline, 'Profile', index: 3),
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
            child: Text((user?.fullName ?? 'A').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.fullName ?? 'Admin Name', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('System Administrator', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, {required int index}) {
    final isActive = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant, size: 20),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
          ),
        ),
        onTap: () => setState(() => _currentIndex = index),
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
            'SECUREGATE ADMIN',
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
            child: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intelligence Dashboard',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSystemStatusBadge(),
              const Spacer(),
              _buildExportButton(),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Intelligence Dashboard',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time campus security telemetry and network health.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildSystemStatusBadge(),
        const SizedBox(width: 12),
        _buildExportButton(),
      ],
    );
  }

  Widget _buildSystemStatusBadge() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'System Online',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.download, size: 18),
      label: const Text('Export Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,           // ← add this
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ← add this
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ← add this
      ),
    );
  }



  Widget _buildTelemetryCard(String label, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(icon, size: 100, color: color.withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trend,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color == AppColors.error ? AppColors.onSurfaceVariant : color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, bool isDesktop, Map<String, int> volume, Map<String, int> breakdown) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildVolumeChart(volume)),
          const SizedBox(width: 24),
          Expanded(child: _buildDeviceBreakdown(breakdown)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildVolumeChart(volume),
          const SizedBox(height: 24),
          _buildDeviceBreakdown(breakdown),
        ],
      );
    }
  }

  Widget _buildVolumeChart(Map<String, int> volume) {
    final spots = volume.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan Volume', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Activity over the last 7 days.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < volume.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              volume.keys.elementAt(value.toInt()),
                              style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceBreakdown(Map<String, int> breakdown) {
    final total = breakdown.values.fold(0, (sum, count) => sum + count);
    final colors = [AppColors.primary, AppColors.secondary, AppColors.error, Colors.orange, Colors.purple];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device Breakdown', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Distribution by manufacturer.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: breakdown.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final count = entry.value.value;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: count.toDouble(),
                    title: '${((count / total) * 100).toStringAsFixed(0)}%',
                    radius: 30,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...breakdown.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final brand = entry.value.key;
            final count = entry.value.value;
            return _buildBreakdownRow(brand, '${((count / total) * 100).toStringAsFixed(1)}%', colors[index % colors.length]);
          }),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTable(BuildContext context, List<Map<String, dynamic>> logs) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Security Events', 
                        style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Audit Log: Detailed history of entries, exits, and system-wide security interactions.', 
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final supabase = Provider.of<SupabaseService>(context, listen: false);
                        final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
                        
                        await PdfService.generateSecurityReport(
                          logs: logs,
                          adminName: user?.fullName ?? 'Admin',
                        );
                        
                        await supabase.logActivity(activityType: 'report_export', status: 'success');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audit log exported successfully')),
                          );
                        }
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _currentIndex = 2),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.6),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1.2), // Increased from 0.8
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest),
                    children: [
                      _buildCell('TIMESTAMP', isHeader: true),
                      _buildCell('OWNER', isHeader: true),
                      _buildCell('DEVICE', isHeader: true),
                      _buildCell('STATUS', isHeader: true),
                      _buildCell('ACTION', isHeader: true),
                    ],
                  ),
                  ...logs.map((log) {
                    final isSystem = log['device_id'] == '00000000-0000-0000-0000-000000000000';
                    final device = log['devices'] as Map<String, dynamic>?;
                    final user = device?['users'] as Map<String, dynamic>?;
                    final timestamp = DateTime.parse(log['created_at']);
                    final timeStr = DateFormat('MMM d, HH:mm').format(timestamp);
                    final status = log['status']?.toString().toUpperCase() ?? 'VERIFIED';
                    final statusColor = status == 'VERIFIED' ? AppColors.secondary : (status == 'INFO' ? AppColors.primary : AppColors.error);

                    return _buildTableRow(
                      timeStr,
                      user?['full_name'] ?? 'Admin/System',
                      isSystem ? (log['entry_type']?.toString().toUpperCase() ?? 'SYSTEM') : '${device?['brand'] ?? ''} ${device?['model'] ?? ''}',
                      status,
                      statusColor,
                      type: log['entry_type']?.toString().toUpperCase(),
                      lat: log['latitude'] is num ? (log['latitude'] as num).toDouble() : null,
                      lng: log['longitude'] is num ? (log['longitude'] as num).toDouble() : null,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHardwareAuditView() {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.getEnrichedDevices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Load Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
        }
        final devices = snapshot.data ?? [];
        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('No devices found in inventory', style: GoogleFonts.inter(fontSize: 18, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Ensure devices are registered in the system.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant.withOpacity(0.7))),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hardware Audit & Inventory', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800)),
                        Text('Real-time tracking of institutional assets and owner correlation.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  _buildStatPulse('TOTAL ASSETS', devices.length.toString()),
                ],
              ),
              const SizedBox(height: 32),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 900),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        _buildAuditTableHeader(),
                        const Divider(height: 1, color: AppColors.outlineVariant),
                        ...devices.map((dev) => _buildInventoryRow(context, dev)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPulse(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
          Text(value, style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
        ],
      ),
    );
  }

  Widget _buildAuditTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          SizedBox(width: 220, child: Text('DEVICE / SERIAL', style: _headerStyle)),
          SizedBox(width: 200, child: Text('OWNER', style: _headerStyle)),
          SizedBox(width: 200, child: Text('LAST SEEN', style: _headerStyle)),
          SizedBox(width: 120, child: Text('RISK LEVEL', style: _headerStyle)),
          SizedBox(width: 100, child: Text('STATUS', style: _headerStyle)),
          SizedBox(width: 140, child: Text('ACTIONS', style: _headerStyle)),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1);

  Widget _buildInventoryRow(BuildContext context, Map<String, dynamic> dev) {
    // Robust data extraction for joins (handles both Map and List returns)
    final userData = dev['users'];
    final Map<String, dynamic>? user = (userData is List && userData.isNotEmpty) 
        ? userData.first as Map<String, dynamic> 
        : (userData is Map ? userData as Map<String, dynamic> : null);
        
    final logsData = dev['verification_logs'];
    final logs = (logsData is List) 
        ? logsData.cast<Map<String, dynamic>>() 
        : (logsData is Map ? [logsData as Map<String, dynamic>] : []);
        
    final lastSeen = logs.isNotEmpty ? logs.last : null; // Get most recent log
    final status = dev['status']?.toString().toLowerCase() ?? 'verified';
    
    Color riskColor = AppColors.secondary; // Low risk
    String riskLabel = 'LOW';
    
    if (status == 'stolen') {
      riskColor = AppColors.error;
      riskLabel = 'CRITICAL';
    } else if (status == 'suspicious') {
      riskColor = Colors.deepOrange;
      riskLabel = 'HIGH';
    } else if (status == 'pending' || logs.isEmpty) {
      riskColor = const Color(0xFFF59E0B); // Amber
      riskLabel = 'MEDIUM';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dev['model'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(dev['serial_number'] ?? 'N/A', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text((user?['full_name'] ?? 'U').substring(0, 1), style: const TextStyle(fontSize: 10, color: AppColors.onSurface)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(user?['full_name'] ?? 'Unassigned', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lastSeen != null ? _formatTime(lastSeen['created_at']) : 'Never Scanned', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      if (lastSeen != null)
                        Text(lastSeen['entry_type']?.toString().toUpperCase() ?? 'CHECKPOINT', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                      if (lastSeen == null && dev['location'] != null)
                        Text(dev['location'], style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (lastSeen != null && lastSeen['latitude'] != null)
                  IconButton(
                    icon: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                    onPressed: () => _launchGPS(lastSeen['latitude'], lastSeen['longitude']),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: Align(alignment: Alignment.centerLeft, child: _buildRiskChip(riskLabel, riskColor)),
          ),
          SizedBox(
            width: 100,
            child: Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(status)),
          ),
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerLeft,
              child: status == 'pending' 
                ? TextButton(
                    onPressed: () => _verifyDevice(context, dev['id']),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Verify Now', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  )
                : const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyDevice(BuildContext context, String deviceId) async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      await supabase.verifyDevice(deviceId);
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device verified successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  }

  Widget _buildRiskChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    final dt = DateTime.parse(time);
    return DateFormat('MMM d, HH:mm').format(dt);
  }

  Future<void> _launchGPS(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStatusBadge(String status) {
    final Color color;
    switch (status) {
      case 'verified': color = AppColors.secondary; break;
      case 'stolen':   color = AppColors.error; break;
      case 'suspicious': color = Colors.deepOrange; break;
      case 'pending':  color = const Color(0xFFF59E0B); break;
      default:         color = AppColors.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSystemLogsView() {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.getEnrichedVerificationLogs(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Audit Logs', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildAuditTable(context, logs),
            ],
          ),
        );
      },
    );
  }

  TableRow _buildTableRow(String time, String owner, String device, String status, Color color, {String? type, double? lat, double? lng}) {
    return TableRow(
      children: [
        _buildCell(time),
        _buildCell(owner, icon: Icons.person_outline),
        _buildCell(device),
        _buildCell(status, badgeColor: color),
        _buildCell(type ?? 'SCAN', badgeColor: type == 'EXIT' ? AppColors.error : AppColors.primary, lat: lat, lng: lng),
      ],
    );
  }

  Widget _buildCell(String text, {bool isHeader = false, IconData? icon, Color? badgeColor, bool isAction = false, double? lat, double? lng}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Reduced horizontal padding
      child: isAction
          ? Icon(Icons.info_outline, color: AppColors.primary, size: 20)
          : badgeColor != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                        if (lat != null) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _launchGPS(lat, lng),
                            child: const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
                    if (icon != null) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: isHeader ? 11 : 13,
                          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                          color: isHeader ? AppColors.onSurfaceVariant : AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
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
          _buildBottomNavItem(Icons.analytics, 'Intell', index: 0),
          _buildBottomNavItem(Icons.fact_check_outlined, 'Audit', index: 1),
          _buildBottomNavItem(Icons.history, 'Logs', index: 2),
          _buildBottomNavItem(Icons.person, 'Profile', index: 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, {required int index}) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
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
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.7, size.width * 0.3, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.95, size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.55, size.height * 0.2); // Spike
    path.lineTo(size.width * 0.6, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.4, size.width, size.height * 0.5);

    canvas.drawPath(path, paint);

    // Fill area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
