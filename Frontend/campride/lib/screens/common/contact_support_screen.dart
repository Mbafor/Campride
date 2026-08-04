import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Contact Support',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.email_outlined, color: AppColors.primaryGreenLight, size: 32),
              const SizedBox(height: 16),
              Text(
                'Email us directly',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For anything not covered by bug reports, feature requests, or '
                'feedback, reach us at the address below.',
                style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.fieldBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ApiConfig.supportEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_outlined, size: 20, color: context.textSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: ApiConfig.supportEmail));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email copied to clipboard', style: GoogleFonts.poppins()),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
