import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/authentication_provider.dart';
import '../../theme/app_theme.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    String? emailErr;
    String? passErr;

    final validEmail =
        RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
    if (!validEmail) emailErr = 'Enter a valid email address';

    if (password.length < 8) {
      passErr = 'Password must be at least 8 characters';
    } else if (password != confirm) {
      passErr = 'Passwords do not match';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    if (emailErr != null || passErr != null) return;

    final auth = context.read<AuthenticationProvider>();
    final ok = await auth.register(
      name: name,
      email: email,
      password: password,
    );

    if (mounted) {
      if (ok) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.fieldFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back,
                        size: 20, color: context.textPrimary),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Create account',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 28),
                _GreyField(
                  controller: _nameCtrl,
                  hint: 'Full name',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),
                _GreyField(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 12),
                _GreyField(
                  controller: _passwordCtrl,
                  hint: 'Password',
                  obscureText: _obscurePassword,
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 12),
                _GreyField(
                  controller: _confirmCtrl,
                  hint: 'Confirm password',
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 28),
                _PrimaryButton(
                    label: 'Create account', onPressed: _handleCreate),
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: context.textSecondary),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreyField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;

  const _GreyField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.fieldBorder, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.poppins(fontSize: 15, color: context.textSecondary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreenDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}

