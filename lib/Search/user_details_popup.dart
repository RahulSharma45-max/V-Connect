import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v_connect/Chat/chat_page.dart';
import 'package:photo_view/photo_view.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class UserDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailsPopup({super.key, required this.userData});

  Future<void> _navigateToChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String? rawOtherId =
        (userData['id'] != null && userData['id'].toString().isNotEmpty)
        ? userData['id'].toString()
        : ((userData['uid'] != null && userData['uid'].toString().isNotEmpty)
              ? userData['uid'].toString()
              : null);

    if (rawOtherId == null ||
        rawOtherId.isEmpty ||
        rawOtherId == currentUser.uid) {
      debugPrint('[UserDetailsPopup] Invalid recipient ID: $rawOtherId');
      return;
    }

    final String otherUserId = rawOtherId;
    final Map<String, dynamic> preparedOtherUser = Map<String, dynamic>.from(
      userData,
    );
    preparedOtherUser['id'] = otherUserId;
    preparedOtherUser['uid'] = otherUserId;

    List<String> ids = [currentUser.uid, otherUserId]..sort();
    String chatRoomId = ids.join('_');

    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId);
      final doc = await chatRef.get();
      if (doc.exists) {
        await chatRef.update({'unreadCount.${currentUser.uid}': 0});
      } else {
        await chatRef.set({
          'participants': [currentUser.uid, otherUserId],
          'isGroup': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': 'Chat started',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUser.uid,
          'unreadCount': {currentUser.uid: 0, otherUserId: 0},
          'archivedBy': {currentUser.uid: false, otherUserId: false},
        });
      }

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatPage(chatRoomId: chatRoomId, otherUser: preparedOtherUser),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[UserDetailsPopup] Error opening chat: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String? _convertGDriveLink(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.contains('drive.google.com/uc?export=view')) {
      return url;
    }

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

  void _showTimetablePopup(BuildContext context, String? timetableUrl) {
    if (timetableUrl == null || timetableUrl.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.table_chart_outlined,
                color: AppColors.maroon,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'No Timetable',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'This user has not uploaded a timetable yet.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(timetableUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  color: AppColors.onPrimary,
                ),
              ),
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.onPrimary.withOpacity(0.7),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load timetable',
                        style: GoogleFonts.inter(
                          color: AppColors.onPrimary.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.table_chart,
                      color: AppColors.onPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Timetable',
                      style: GoogleFonts.inter(
                        color: AppColors.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String name = userData['name'] ?? 'No Name';
    final String email = userData['email'] ?? 'No Email';
    final String dept = userData['dept'] ?? 'N/A';
    final String customId = userData['customId'] ?? 'N/A';

    final String uid = userData['uid'] ?? userData['id'];
    final String? photoUrl = _convertGDriveLink(userData['photoUrl']);

    // ✅ FIXED: Now reads `phoneNumber` (fallback `phone`)
    final String phoneNumber =
        userData['phoneNumber'] ?? userData['phone'] ?? '';

    final bool isOwnProfile = currentUser?.uid == uid;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: VSheetHandle(),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: double.infinity,
                  color: AppColors.surfaceAlt,
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) {
                            return _imageFallback(name);
                          },
                        )
                      : _imageFallback(name),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 24);

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final bool isPresent = data?['isPresent'] ?? false;

                    return VStatusChip(isPresent: isPresent);
                  },
                ),

                const Divider(height: 28),

                _buildDetailRow(Icons.email_outlined, email),

                if (phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.phone_outlined, phoneNumber),
                ],

                const SizedBox(height: 12),
                _buildDetailRow(Icons.business_center_outlined, dept),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.badge_outlined, "ID: $customId"),

                const Divider(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String? timetableUrl;
                          if (snapshot.hasData && snapshot.data != null) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            timetableUrl = _convertGDriveLink(
                              data?['timetableUrl'],
                            );
                          }

                          return OutlinedButton.icon(
                            onPressed: () =>
                                _showTimetablePopup(context, timetableUrl),
                            icon: const Icon(Icons.table_chart, size: 18),
                            label: const Text("Timetable"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          );
                        },
                      ),
                    ),
                    if (!isOwnProfile) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToChat(context),
                          icon: const Icon(Icons.message_outlined, size: 18),
                          label: const Text("Chat"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(String name) {
    return Container(
      color: AppColors.surfaceAlt,
      child: Center(
        child: CircleAvatar(
          radius: 56,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.inter(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
