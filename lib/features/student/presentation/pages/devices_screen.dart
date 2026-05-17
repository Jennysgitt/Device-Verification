import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lightmode/core/backend/providers/auth_provider.dart';
import 'package:lightmode/core/backend/models/device_model.dart';
import 'package:lightmode/core/backend/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/backend/services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  bool _isSaving = false;
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = Provider.of<AuthProvider>(context).devices;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Registry',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your devices and their access permissions.',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          if (devices.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.devices_other, size: 64, color: AppColors.surfaceVariant),
                  const SizedBox(height: 16),
                  Text('No devices registered yet', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final device = devices[index];
                return _buildDeviceCard(context, device);
              },
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRegisterDeviceDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Register New Device'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Register Device', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Enter your hardware details for institutional verification.', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  // Image Capture Section
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          setModalState(() => _capturedImage = image);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _capturedImage != null ? AppColors.secondary : AppColors.outlineVariant, style: BorderStyle.solid),
                        ),
                        child: _capturedImage != null 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.outline),
                                const SizedBox(height: 8),
                                Text('Capture Hardware Photo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.outline)),
                              ],
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputField('BRAND', 'e.g. Apple, Samsung', _brandController),
                  const SizedBox(height: 16),
                  _buildInputField('MODEL', 'e.g. iPhone 15, Galaxy S23', _modelController),
                  const SizedBox(height: 16),
                  _buildInputField('SERIAL NUMBER', 'Check settings or back of device', _serialController),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () async {
                        if (_brandController.text.isEmpty || _modelController.text.isEmpty || _serialController.text.isEmpty || _capturedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and capture a photo')));
                          return;
                        }
                        
                        setModalState(() => _isSaving = true);
                        
                        try {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final supabase = Provider.of<SupabaseService>(context, listen: false);
                          final api = Provider.of<ApiService>(context, listen: false);
                          
                          // 1. Upload to Storage
                          final bytes = await _capturedImage!.readAsBytes();
                          final fileName = '${auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          final publicUrl = await supabase.uploadImage(fileName, bytes);

                          // 2. Extract Features via AI API
                          final aiResult = await api.registerDeviceWithAI(
                            brand: _brandController.text.trim(),
                            model: _modelController.text.trim(),
                            serialNumber: _serialController.text.trim(),
                            imageUrl: publicUrl,
                          );

                          final List<double> features = (aiResult['features'] as List).cast<double>();

                          // 3. Create Device Record
                          await supabase.createDevice(
                            userId: auth.currentUser!.id,
                            brand: _brandController.text.trim(),
                            model: _modelController.text.trim(),
                            serialNumber: _serialController.text.trim(),
                            imageUrl: publicUrl,
                            features: features,
                          );
                          
                          await auth.reloadUser(); // Refresh device list
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _brandController.clear();
                            _modelController.clear();
                            _serialController.clear();
                            _capturedImage = null;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device registered with AI verification!')));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        } finally {
                          setModalState(() => _isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Registration'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
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

  Widget _buildInputField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.outline, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
            filled: true,
            fillColor: AppColors.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, DeviceModel device) {
    final isVerified = device.status == 'verified';
    final isStolen = device.status == 'stolen';
    final statusColor = isVerified ? AppColors.secondary : (isStolen ? AppColors.error : AppColors.primary);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  device.brand.toLowerCase().contains('apple') ? Icons.phone_iphone : Icons.phone_android, 
                  color: statusColor
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${device.brand} ${device.model}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            device.status.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    Text('S/N: ${device.serialNumber}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('Registered: ${DateFormat('MMM dd, yyyy').format(device.createdAt)}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.outline)),
                  ],
                ),
              ),
              if (!isStolen)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'stolen') {
                      _reportStolen(context, device);
                    } else if (value == 'qr') {
                      _showDeviceQrCode(context, device);
                    } else if (value == 'remove') {
                      _removeDevice(context, device);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'qr',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('View QR Code'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'stolen',
                      child: Row(
                        children: [
                          Icon(Icons.report_problem, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('Report Stolen', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('Remove Device', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (isStolen && device.location != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reported stolen at: ${device.location}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _reportStolen(BuildContext context, DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Stolen?'),
        content: const Text('This will flag the device across the campus security network. This action cannot be undone by students.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final supabase = Provider.of<SupabaseService>(context, listen: false);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                
                await supabase.updateDeviceStatus(device.id, 'stolen', location: 'Reported by owner');
                await auth.reloadUser();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device reported stolen. Security alerted.')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Report Stolen'),
          ),
        ],
      ),
    );
  }

  void _removeDevice(BuildContext context, DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device?'),
        content: const Text('This will deactivate the device from your registry. You will need to re-register it to gain access again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final supabase = Provider.of<SupabaseService>(context, listen: false);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                
                await supabase.updateDeviceStatus(device.id, 'deactivated');
                await auth.reloadUser();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device deactivated.')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDeviceQrCode(BuildContext context, DeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Device QR Code', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${device.brand} ${device.model}', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 32),
              QrImageView(
                data: device.qrCodeHash ?? device.qrCodeUrl ?? device.id,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
