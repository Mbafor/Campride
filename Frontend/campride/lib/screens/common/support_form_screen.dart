import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/authentication_provider.dart';
import '../../theme/app_theme.dart';

String _guessImageContentType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}

/// Form for the three ticket-based Support actions, each with its own
/// field layout:
///  - Report a bug: title, description, optional screenshot.
///  - Feature request: title, description.
///  - Leave feedback: star rating, optional comment.
class SupportFormScreen extends StatefulWidget {
  final String title;
  final String ticketType;

  const SupportFormScreen({
    super.key,
    required this.title,
    required this.ticketType,
  });

  @override
  State<SupportFormScreen> createState() => _SupportFormScreenState();
}

class _SupportFormScreenState extends State<SupportFormScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _picker = ImagePicker();

  int _rating = 0;
  Uint8List? _screenshotBytes;
  String? _screenshotFilename;

  bool _isLoading = false;
  String? _error;

  bool get _isBug => widget.ticketType == 'bug';
  bool get _isFeature => widget.ticketType == 'feature';
  bool get _isFeedback => widget.ticketType == 'feedback';

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _screenshotBytes = bytes;
      _screenshotFilename = picked.name;
    });
  }

  Future<void> _submit() async {
    String? title;
    String? message;
    int? rating;

    if (_isBug || _isFeature) {
      title = _titleController.text.trim();
      message = _messageController.text.trim();
      if (title.isEmpty) {
        setState(() => _error = 'Please enter a title');
        return;
      }
      if (message.isEmpty) {
        setState(() => _error = 'Please enter a description');
        return;
      }
    } else if (_isFeedback) {
      if (_rating == 0) {
        setState(() => _error = 'Please rate your experience');
        return;
      }
      rating = _rating;
      final comment = _messageController.text.trim();
      message = comment.isEmpty ? null : comment;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      String? screenshotDataUrl;
      if (_isBug && _screenshotBytes != null) {
        final mime = _guessImageContentType(_screenshotFilename ?? 'screenshot.jpg');
        screenshotDataUrl = 'data:$mime;base64,${base64Encode(_screenshotBytes!)}';
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseHttpUrl}/support/tickets'),
            headers: {
              'Authorization': 'Bearer ${auth.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'type': widget.ticketType,
              'title': ?title,
              'message': ?message,
              'rating': ?rating,
              'screenshot_data_url': ?screenshotDataUrl,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Text('Thanks — we received your message',
                    style: GoogleFonts.poppins(color: context.textPrimary)),
              ],
            ),
            backgroundColor: context.cardBg,
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
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
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
              if (_isFeedback) ..._buildFeedbackFields() else ..._buildTitleDescriptionFields(),
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

  List<Widget> _buildTitleDescriptionFields() {
    return [
      Text(
        'Title',
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
      ),
      const SizedBox(height: 8),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fieldBorder, width: 1.5),
        ),
        child: TextField(
          controller: _titleController,
          style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: _isBug ? 'Short summary of the issue' : 'Short summary of your idea',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Description',
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
      ),
      const SizedBox(height: 8),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fieldBorder, width: 1.5),
        ),
        child: TextField(
          controller: _messageController,
          maxLines: 6,
          style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: _isBug
                ? 'What went wrong? Include what you were doing when it happened.'
                : 'What would you like to see added or changed?',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
      if (_isBug) ...[
        const SizedBox(height: 20),
        Text(
          'Screenshot (optional)',
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
        ),
        const SizedBox(height: 8),
        _buildScreenshotPicker(),
      ],
    ];
  }

  Widget _buildScreenshotPicker() {
    if (_screenshotBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _screenshotBytes!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() {
                _screenshotBytes = null;
                _screenshotFilename = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pickScreenshot,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: context.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fieldBorder, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: context.textSecondary, size: 26),
            const SizedBox(height: 6),
            Text(
              'Add a screenshot',
              style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedbackFields() {
    return [
      Text(
        'Rate your experience',
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
      ),
      const SizedBox(height: 10),
      Row(
        children: List.generate(5, (i) {
          final filled = i < _rating;
          return GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                filled ? Icons.star : Icons.star_border,
                color: AppColors.accentGold,
                size: 38,
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 24),
      Text(
        'Comment (optional)',
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
      ),
      const SizedBox(height: 8),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.fieldBorder, width: 1.5),
        ),
        child: TextField(
          controller: _messageController,
          maxLines: 6,
          style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tell us what you think about CampRide.',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    ];
  }
}
