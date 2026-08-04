import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/authentication_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/common/profile_avatar_view.dart';
import 'update_name_screen.dart';
import 'update_gender_screen.dart';
import 'update_phone_screen.dart';
import 'update_email_screen.dart';

/// Profile screen reached from the Account tab → Profile.
/// Each row opens the corresponding edit screen from the design.
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child:
                    Icon(Icons.arrow_back, size: 24, color: context.textPrimary),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Center(child: _ProfileAvatar()),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Personal info',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(height: 1, thickness: 1, color: context.divider),
            Expanded(
              child: Consumer<AuthenticationProvider>(
                builder: (context, auth, _) {
                  final user = auth.user;
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _InfoRow(
                        label: 'Name',
                        value: user?.name ?? '—',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UpdateNameScreen()),
                        ),
                      ),
                      _InfoRow(
                        label: 'Gender',
                        value: user?.gender?.isNotEmpty == true
                            ? user!.gender!
                            : 'Not set',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UpdateGenderScreen()),
                        ),
                      ),
                      _InfoRow(
                        label: 'Phone number',
                        value: user?.phoneNumber?.isNotEmpty == true
                            ? user!.phoneNumber!
                            : 'Not set',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UpdatePhoneScreen()),
                        ),
                      ),
                      _InfoRow(
                        label: 'Email',
                        value: user?.email ?? '—',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UpdateEmailScreen()),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable avatar that lets the student take/choose a profile photo and
/// uploads it. Shows the current photo when set, otherwise the default icon.
class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar();

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);

    final bytes = await picked.readAsBytes();
    final auth = context.read<AuthenticationProvider>();
    final success = await auth.updateProfilePhoto(
      bytes: bytes,
      filename: picked.name,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Failed to update photo')),
      );
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Take photo', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Choose from gallery', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthenticationProvider>().user;

    return GestureDetector(
      onTap: _isUploading ? null : _showPickerSheet,
      child: Stack(
        children: [
          ProfileAvatarView(photoUrl: user?.photoUrl, name: user?.name, size: 84),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.textSecondary, size: 22),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: context.divider),
      ],
    );
  }
}
