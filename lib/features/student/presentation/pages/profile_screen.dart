import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../../core/backend/providers/auth_provider.dart';
import '../../../../core/backend/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _departmentController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.fullName);
    _departmentController = TextEditingController(text: user?.department);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    
    try {
      if (auth.currentUser == null) return;
      
      await supabase.updateUserProfile(
        userId: auth.currentUser!.id,
        fullName: _nameController.text.trim(),
      );
      
      // Update department if it exists on the record
      await supabase.updateUserDepartment(
        userId: auth.currentUser!.id,
        department: _departmentController.text.trim(),
      );

      await auth.reloadUser();
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.secondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileHeader(user),
          const SizedBox(height: 40),
          _buildInfoSection('Personal Information', [
            _buildInfoItem('Student ID', user?.studentId?.toUpperCase() ?? 'N/A'),
            _buildEditableInfoItem('Full Name', _nameController, _isEditing),
            _buildEditableInfoItem('Department', _departmentController, _isEditing),
            _buildInfoItem('Account Role', user?.role.toUpperCase() ?? 'STUDENT'),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Contact Details', [
            _buildInfoItem('Email', user?.email ?? '-'),
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isEditing ? _handleSave : () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? AppColors.primary : AppColors.surfaceVariant,
                foregroundColor: _isEditing ? Colors.white : AppColors.onSurface,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              alignment: Alignment.center,
              child: Text(
                (user?.fullName ?? "S").substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.fullName ?? 'Student Name',
          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        Text(
          'University Member',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
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

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEditableInfoItem(String label, TextEditingController controller, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 24),
          Expanded(
            child: isEditing 
              ? TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  controller.text.isEmpty ? 'N/A' : controller.text, 
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)
                ),
          ),
        ],
      ),
    );
  }
}
