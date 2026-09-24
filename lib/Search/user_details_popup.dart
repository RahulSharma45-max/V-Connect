import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v_connect/Chat/chat_page.dart';
import 'package:photo_view/photo_view.dart';

class UserDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailsPopup({super.key, required this.userData});

  void _navigateToChat(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String uid = userData['uid'] ?? userData['id'];

    List<String> ids = [currentUser.uid, uid];
    ids.sort();
    String chatRoomId = ids.join('_');

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatPage(chatRoomId: chatRoomId, otherUser: userData),
      ),
    );
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
        barrierColor: Colors.black.withOpacity(0.8),
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Row(
            children: [
              Icon(
                Icons.table_chart,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'No Timetable',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'This user has not uploaded a timetable yet.',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  color: Colors.white,
                ),
              ),
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load timetable',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.table_chart,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Timetable',
                      style: GoogleFonts.inter(
                        color: Colors.white,
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
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
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
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            return _imageFallback(name);
                          },
                        )
                      : _imageFallback(name),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

                    return _buildStatusIndicator(isPresent);
                  },
                ),

                Divider(color: Colors.white.withOpacity(0.2), height: 30),

                _buildDetailRow(Icons.email_outlined, email),

                if (phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.phone_outlined, phoneNumber),
                ],

                const SizedBox(height: 12),
                _buildDetailRow(Icons.business_center_outlined, dept),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.badge_outlined, "ID: $customId"),

                Divider(color: Colors.white.withOpacity(0.2), height: 30),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String? timetableUrl;
                    if (snapshot.hasData && snapshot.data != null) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      timetableUrl = _convertGDriveLink(data?['timetableUrl']);
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showTimetablePopup(context, timetableUrl),
                        icon: const Icon(Icons.table_chart, size: 20),
                        label: const Text("View Timetable"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                if (!isOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToChat(context),
                      icon: const Icon(Icons.message_outlined, size: 20),
                      label: const Text("Chat"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white.withOpacity(0.15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(String name) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPresent
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isPresent ? "PRESENT" : "ABSENT",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
