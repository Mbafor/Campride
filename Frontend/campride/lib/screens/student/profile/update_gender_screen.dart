import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../theme/theme_extensions.dart';

/// "Choose your gender" screen.
/// Woman / Man radio options + Remove Information / Submit buttons.
class UpdateGenderScreen extends StatefulWidget {
  const UpdateGenderScreen({super.key});

  @override
  State<UpdateGenderScreen> createState() => _UpdateGenderScreenState();
}

class _UpdateGenderScreenState extends State<UpdateGenderScreen> {
  String? _selected;
  String _current = 'Man';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthenticationProvider>().user;
    _current = user?.gender ?? 'Man';
    _selected = _current;
  }

  Future<void> _submit() async {
    if (_selected == null) {
      _showMessage('Please select a gender');
      return;
    }

    setState(() => _saving = true);
    final success =
        await context.read<AuthenticationProvider>().updateProfile(gender: _selected);
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      _showMessage('Failed to update gender. Please try again.');
    }
  }

  Future<void> _removeInformation() async {
    setState(() => _saving = true);
    final success =
        await context.read<AuthenticationProvider>().updateProfile(gender: '');
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      _showMessage('Failed to remove gender. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHOOSE GENDER',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.3,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose your gender',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the option that best represents your gender.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How we use your gender data',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your gender information may be used for safety features, personalization of ads and marketing, and ad measurement. We won\'t show your gender to anyone unless you are opted in to relevant features. You can manage this information in Account Settings.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _GenderOption(
                      label: 'Woman',
                      selected: _selected == 'Woman',
                      onTap: () => setState(() => _selected = 'Woman'),
                    ),
                    Divider(height: 1, thickness: 1, color: context.divider),
                    _GenderOption(
                      label: 'Man',
                      selected: _selected == 'Man',
                      onTap: () => setState(() => _selected = 'Man'),
                    ),
                    Divider(height: 1, thickness: 1, color: context.divider),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  _PillButton(
                    label: 'Remove Information',
                    onTap: _saving ? null : _removeInformation,
                    showProgress: false,
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: 'Submit',
                    onTap: _saving ? null : _submit,
                    showProgress: _saving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.textPrimary : context.textSecondary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: context.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool showProgress;

  const _PillButton({
    required this.label,
    this.onTap,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: context.fieldFill,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: showProgress
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.textPrimary,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
      ),
    );
  }
}
