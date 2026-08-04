import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/authentication_provider.dart';
import '../../theme/app_theme.dart';

/// Reusable form for the three ticket-based Support actions
/// (Report a bug, Feature request, Leave feedback) — only the copy and
/// the `type` sent to the backend differ between them.
class SupportFormScreen extends StatefulWidget {
  final String title;
  final String ticketType;
  final String hint;

  const SupportFormScreen({
    super.key,
    required this.title,
    required this.ticketType,
    required this.hint,
  });

  @override
  State<SupportFormScreen> createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends State<SupportFormScreen> {
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please enter a message');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseHttpUrl}/support/tickets'),
            headers: {
              'Authorization': 'Bearer ${auth.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'type': widget.ticketType, 'message': message}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Text('Thanks — we received your message', style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.green[50],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _error = 'Failed to send. Please try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.fieldBorder, width: 1.5),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 8,
                  style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600])),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Send', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
