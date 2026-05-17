import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lightmode/core/theme/app_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:lightmode/core/backend/services/supabase_service.dart';
import 'package:lightmode/core/backend/providers/auth_provider.dart';
import 'package:lightmode/core/backend/services/api_service.dart';
import 'package:lightmode/core/backend/services/notification_service.dart';
import 'package:image_picker/image_picker.dart';

class VerificationView extends StatefulWidget {
  const VerificationView({super.key});

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  final MobileScannerController controller = MobileScannerController();
  bool isVerified = false;
  String? scannedCode;
  String _entryType = 'entry';
  bool _isProcessing = false;
  Map<String, dynamic>? _deviceData;
  double _aiScore = 0.0;
  String _aiStatus = 'PENDING';
  String? _currentLogId; // Track log across phases
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Geolocator.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
          ),
        ],
      ),
      bottomNavigationBar: null, // Removed redundant bottom nav to fix "Profile" selection bug
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildViewfinder(context)),
        Container(
          width: 450,
          color: AppColors.surface,
          child: _buildVerificationDetails(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildMobileHeader(context),
        Expanded(
          child: Stack(
            children: [
              _buildViewfinder(context),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: _buildVerificationDetails(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'SecureGate Admin',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
          ),
          _buildSidebarItem(Icons.analytics, 'Intelligence', isActive: true),
          _buildSidebarItem(Icons.fact_check_outlined, 'Device Registry'),
          _buildSidebarItem(Icons.group_work_outlined, 'User Audit'),
          _buildSidebarItem(Icons.settings_outlined, 'Settings'),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(color: isActive ? AppColors.secondaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant, size: 20),
        title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant)),
        onTap: () {},
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Scanner', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppColors.primary),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: AppColors.primary),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder(BuildContext context) {
    return Stack(
      children: [
        // Camera Feed
        MobileScanner(
          controller: controller,
          onDetect: (capture) async {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && !isVerified && !_isProcessing) {
              final code = barcodes.first.rawValue;
              if (code != null) {
                _handleDetection(code);
              }
            }
          },
        ),
        // Overlay for feedback if verified
        if (isVerified)
          Container(
            color: AppColors.secondary.withOpacity(0.2),
            child: Center(
              child: const Icon(Icons.check_circle, color: AppColors.secondary, size: 80)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
            ),
          ),
        // Reticle
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF6FFBBE), width: 1),
              boxShadow: [BoxShadow(color: const Color(0xFF6FFBBE).withOpacity(0.3), blurRadius: 10)],
            ),
            child: Stack(
              children: [
                _buildCorner(0, 0, isTop: true, isLeft: true),
                _buildCorner(null, 0, isTop: true, isRight: true),
                _buildCorner(0, null, isBottom: true, isLeft: true),
                _buildCorner(null, null, isBottom: true, isRight: true),
                Center(child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF6FFBBE), shape: BoxShape.circle))),
              ],
            ),
          ),
        ),
        // Live Feed Badge
        Positioned(
          top: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2))),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).scale(duration: 1.seconds, curve: Curves.easeInOut),
                const SizedBox(width: 8),
                Text('LIVE FEED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(double? left, double? top, {bool isRight = false, bool isBottom = false, bool isTop = false, bool isLeft = false}) {
    return Positioned(
      left: left, top: top, right: isRight ? 0 : null, bottom: isBottom ? 0 : null,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFF6FFBBE), width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF6FFBBE), width: 4) : BorderSide.none,
            right: isRight ? const BorderSide(color: Color(0xFF6FFBBE), width: 4) : BorderSide.none,
            bottom: isBottom ? const BorderSide(color: Color(0xFF6FFBBE), width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationDetails(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isVerified) ...[
            Text(
              'SCAN CONFIGURATION',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  _buildToggleItem('ENTRY SCAN', 'entry'),
                  _buildToggleItem('EXIT SCAN', 'exit'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          Center(
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: (isVerified ? AppColors.secondary : AppColors.outlineVariant).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVerified ? Icons.check_circle : Icons.qr_code_scanner,
                    color: isVerified ? AppColors.secondary : AppColors.outlineVariant,
                    size: 40,
                  ),
                ).animate(target: isVerified ? 1 : 0).scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  _isProcessing ? 'Processing...' : (isVerified ? (_aiStatus == 'QR MATCHED' ? 'Identity Identified' : 'Device Verified') : 'Scanning...'),
                  style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  isVerified 
                    ? (_aiStatus == 'QR MATCHED' 
                        ? 'QR validated. Please perform hardware AI match.' 
                        : 'Identity confirmed via multipoint AI analysis.')
                    : (_isProcessing ? 'Validating credentials and capturing location...' : 'Align QR code within the viewfinder to begin.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (isVerified) ...[
            _buildAIPanel(),
            const SizedBox(height: 24),
            if (_aiStatus == 'PENDING' || _aiStatus == 'QR MATCHED')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _performAIVerification,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture for AI Match'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else ...[
              _buildMetaInfo(),
              const SizedBox(height: 48),
              Row(
                children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => isVerified = false),
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    label: const Text('Scan Again'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Finish'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    ),
                  ),
                ],
              ),
            ],
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIPanel() {
    final user = _deviceData?['users'] as Map<String, dynamic>?;
    final studentId = (user?['student_ids'] as List?)?.last?['student_id'] as String? ?? 'N/A';
    final confidencePercent = (_aiScore * 100).toStringAsFixed(1);
    final statusColor = _aiStatus == 'VERIFIED' ? AppColors.secondary : (_aiStatus == 'PENDING' ? AppColors.outline : AppColors.error);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_aiStatus != 'QR MATCHED') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Match Confidence', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (_deviceData?['ai_features'] == null && _aiStatus != 'PENDING')
                      Text('⚠️ Features missing in registry', style: GoogleFonts.inter(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    Text('$confidencePercent%', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)),
                    const SizedBox(width: 4),
                    Icon(_aiStatus == 'SUSPICIOUS' ? Icons.warning_amber_rounded : Icons.trending_up, color: statusColor, size: 16),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.surfaceVariant),
          ],
          _buildAIRow(Icons.person, 'Owner', user?['full_name'] ?? 'Unknown', statusColor: _aiStatus == 'PENDING' ? AppColors.onSurface : AppColors.secondary),
          const SizedBox(height: 12),
          _buildAIRow(Icons.badge, 'Student ID', studentId, statusColor: _aiStatus == 'PENDING' ? AppColors.onSurface : AppColors.secondary),
          const SizedBox(height: 12),
          _buildAIRow(Icons.smartphone, 'Device', '${_deviceData?['brand']} ${_deviceData?['model']}', statusColor: _aiStatus == 'PENDING' ? AppColors.onSurface : AppColors.secondary),
          const SizedBox(height: 12),
          _buildAIRow(Icons.qr_code, 'Registry Status', _aiStatus, statusColor: statusColor),
        ],
      ),
    );
  }

  Widget _buildAIRow(IconData icon, String label, String status, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.outline, size: 18),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ],
        ),
        Text(status, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor ?? AppColors.secondary)),
      ],
    );
  }

  Widget _buildMetaInfo() {
    final logs = (_deviceData?['verification_logs'] as List?) ?? [];
    Map<String, dynamic>? lastLog;
    if (logs.isNotEmpty) {
      lastLog = logs.last; // Most recent log
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.horizontal(right: Radius.circular(8)), border: Border(left: BorderSide(color: AppColors.primary, width: 4))),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.schedule, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scan History', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(_entryType.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                Text(
                  lastLog != null 
                    ? 'Last seen: ${_formatTimeAgo(DateTime.parse(lastLog['created_at']))} • ${lastLog['entry_type'].toString().toUpperCase()}'
                    : 'First time verification for this cycle.',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildToggleItem(String label, String value) {
    final isActive = _entryType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _entryType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDetection(String data) async {
    setState(() {
      _isProcessing = true;
      scannedCode = data;
      _aiStatus = 'PENDING';
      _aiScore = 0.0;
      _currentLogId = null;
    });

    try {
      final supabase = Provider.of<SupabaseService>(context, listen: false);
      final officer = Provider.of<AuthProvider>(context, listen: false).currentUser;

      // 1. Immediate Location Capture
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('Initial location capture failed: $e');
      }

      // 2. Parse Data
      String deviceId = data;
      if (data.contains('|')) {
        deviceId = data.split('|').last;
      }

      // 3. Fetch Device Details
      final devDetails = await supabase.getDeviceDetailWithOwner(deviceId);
      
      if (devDetails != null) {
        final deviceStatus = devDetails['status']?.toString().toLowerCase();
        
        if (deviceStatus == 'pending') {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _aiStatus = 'REJECTED';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification Blocked: This device is awaiting Admin approval.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final isStolen = deviceStatus == 'stolen';
        final logStatus = isStolen ? 'suspicious' : 'verified';

        // 4. IMMEDIATE LOGGING (QR Phase)
        _currentLogId = await supabase.createVerificationLog(
          deviceId: devDetails['id'],
          officerId: officer?.id,
          status: logStatus,
          qrValidity: true,
          entryType: _entryType,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );

        if (isStolen) {
          // Trigger instant alert for stolen device
          Provider.of<NotificationService>(context, listen: false).sendNotification(
            userId: officer?.id ?? '',
            title: '🚨 STOLEN DEVICE DETECTED',
            message: 'Device ${devDetails['brand']} ${devDetails['model']} (S/N: ${devDetails['serial_number']}) was scanned! Location recorded.',
            priority: 'emergency',
            category: 'security_alert',
          );
        }

        if (mounted) {
          setState(() {
            _deviceData = devDetails;
            isVerified = true;
            _aiStatus = isStolen ? 'SUSPICIOUS (STOLEN)' : 'QR MATCHED';
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isStolen ? 'ALERT: Device reported stolen!' : 'QR Valid. Proceed to AI Image Match.'), 
              backgroundColor: isStolen ? AppColors.error : AppColors.secondary
            ),
          );
        }
      } else {
        throw Exception('Device not found in registry');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _performAIVerification() async {
    if (_deviceData == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final supabase = Provider.of<SupabaseService>(context, listen: false);
      final officer = Provider.of<AuthProvider>(context, listen: false).currentUser;

      // 1. Capture Live Photo
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // 2. Capture Location
      Position? position;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high, // Increased to High
            timeLimit: const Duration(seconds: 5), // Increased to 5s
          );
        }
      } catch (e) {
        debugPrint('Location capture failed: $e');
      }

      // 3. Upload Live Capture to Storage
      final bytes = await image.readAsBytes();
      final fileName = 'verification_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final liveImageUrl = await supabase.uploadImage(fileName, bytes, bucket: 'verification-images');

      // 4. Call AI API
      final List<double>? registeredFeatures = (_deviceData!['ai_features'] as List?)?.cast<double>();
      
      final aiResponse = await api.verifyDeviceWithAI(
        deviceId: _deviceData!['id'],
        qrHash: _deviceData!['qr_code_hash'] ?? 'N/A',
        liveImageUrl: liveImageUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        registeredFeatures: registeredFeatures,
      );

      final String status = aiResponse['status'] ?? 'failed';
      final double score = (aiResponse['score'] as num?)?.toDouble() ?? 0.0;
      
      // 5. Trigger Security Notification if Suspicious
      if (status == 'suspicious') {
        final notificationContent = 'Suspicious access attempt detected for device ${_deviceData!['brand']} ${_deviceData!['model']} at ${position?.latitude}, ${position?.longitude}. AI Similarity: ${(score * 100).toStringAsFixed(1)}%';
        
        // Notify the current Officer
        Provider.of<NotificationService>(context, listen: false).sendNotification(
          userId: officer?.id ?? '',
          title: '⚠️ SECURITY ALERT',
          message: notificationContent,
          priority: 'high',
          category: 'security_alert',
        );
        
        // Also notify the Student/Owner
        Provider.of<NotificationService>(context, listen: false).sendNotification(
          userId: _deviceData!['user_id'] ?? '',
          title: '🚨 SECURITY NOTICE',
          message: 'Someone is attempting to verify your device. If this isn\'t you, report it immediately!',
          priority: 'emergency',
          category: 'security_alert',
        );
      }


      // 5. Update existing log with AI results
      if (_currentLogId != null) {
        await supabase.updateScanResult(
          logId: _currentLogId!,
          status: status,
          aiScore: score,
        );
      } else {
        // Fallback for direct AI verification if no QR log exists (unlikely)
        await supabase.createVerificationLog(
          deviceId: _deviceData!['id'],
          officerId: officer?.id,
          status: status,
          aiScore: score,
          imageMatchScore: score,
          qrValidity: true,
          entryType: _entryType,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );
      }

      // Debug Logging as requested
      debugPrint('VERIFICATION_LOG_AUDIT: ${[
        {
          "device_id": _deviceData!['id'],
          "officer_id": officer?.id,
          "status": status,
          "ai_score": score.toStringAsFixed(2),
          "qr_validity": true,
          "image_match_score": score.toStringAsFixed(4),
          "entry_type": _entryType,
          "created_at": DateTime.now().toIso8601String(),
          "latitude": position?.latitude,
          "longitude": position?.longitude,
        }
      ]}');

      if (mounted) {
        setState(() {
          _aiScore = score;
          _aiStatus = status.toUpperCase();
          _isProcessing = false;
        });

        if (score == 0.0 && registeredFeatures == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: This device was registered without AI hardware features. Similarity cannot be verified.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Error Logging as requested
      debugPrint('VERIFICATION_ERROR_AUDIT: ${[
        {
          "device_id": _deviceData?['id'],
          "error": e.toString(),
          "timestamp": DateTime.now().toIso8601String(),
          "phase": "image_verification"
        }
      ]}');

      if (mounted) {
        setState(() => _isProcessing = false);
        String errorMessage = e.toString();
        
        // Handle specific bucket error
        if (errorMessage.contains('bucket_not_found') || errorMessage.contains('404')) {
          errorMessage = 'Configuration Error: Supabase bucket "verification-images" not found. Please create it in your storage dashboard.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
          ),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}
