import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Decodes a `data:<mime>;base64,<data>` URL into raw bytes.
/// Returns null if [dataUrl] is null or not a valid data URL.
Uint8List? decodeProfilePhotoDataUrl(String? dataUrl) {
  if (dataUrl == null) return null;
  final commaIndex = dataUrl.indexOf(',');
  if (!dataUrl.startsWith('data:') || commaIndex == -1) return null;
  try {
    return base64Decode(dataUrl.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

/// First-and-last-initial (e.g. "John Doe" -> "JD"), or the first two
/// letters of a single name (e.g. "John" -> "JO"). Returns null if [name]
/// is null/blank.
String? avatarInitials(String? name) {
  if (name == null) return null;
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  final single = parts[0];
  return (single.length >= 2 ? single.substring(0, 2) : single).toUpperCase();
}

/// Read-only circular avatar. Shows, in order of preference: the user's
/// uploaded profile photo (stored as a base64 data URL), an external photo
/// URL (e.g. from Google sign-in), the user's initials, or a generic
/// person icon if no name is available either.
class ProfileAvatarView extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const ProfileAvatarView({
    super.key,
    required this.photoUrl,
    this.name,
    this.size = 54,
    this.backgroundColor = const Color(0xFF2C2C2C),
    this.iconColor = const Color(0xFFBDBDBD),
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodeProfilePhotoDataUrl(photoUrl);
    final isNetworkUrl = bytes == null &&
        photoUrl != null &&
        (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://'));
    final initials = avatarInitials(name);

    Widget fallback() => initials != null
        ? Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
            child: Icon(Icons.person, size: size * 0.58, color: iconColor),
          );

    if (bytes != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(bytes, fit: BoxFit.cover, width: size, height: size),
      );
    }

    if (isNetworkUrl) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => fallback(),
        ),
      );
    }

    return fallback();
  }
}
