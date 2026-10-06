import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:v_connect/theme/app_theme.dart';

/// Turns a Google Drive share link into a direct image link. Links that are
/// already direct (or not Drive links) are returned unchanged.
String? directTimetableUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.contains('drive.google.com/uc?export=view')) return url;

  final patterns = [
    RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
    RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(url);
    if (match != null && match.group(1) != null) {
      return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
    }
  }
  return url;
}

/// Full-screen, zoomable timetable image.
void showTimetableViewer(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null || event.expectedTotalBytes == null
                    ? null
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
