import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v_connect/LoginPage/login_page.dart';
import 'package:v_connect/Profile/edit_profile.dart';
import 'package:v_connect/Faculty/faculty_profile_page.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

// Note: You will need to create this page if it doesn't exist
// import 'package:v_connect/Profile/notification_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        final user = snapshot.data!;
        final userEmail = user.email ?? "no-email@example.com";

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const VAppBar(title: "Profile"),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _profileHeaderCard(context, user: user, userEmail: userEmail),
              VSectionCard(
                title: "Account",
                icon: Icons.manage_accounts_outlined,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _settingsTile(
                      icon: Icons.account_box_outlined,
                      title: "My Faculty Profile",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FacultyProfilePage(facultyId: user.uid),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _settingsTile(
                      icon: Icons.edit_outlined,
                      title: "Edit Profile",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _settingsTile(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      onTap: () async {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: userEmail,
                          );
                          showVSnackBar(
                            context,
                            "Password reset email sent to $userEmail.",
                          );
                        } catch (e) {
                          showVSnackBar(
                            context,
                            "Failed to send email. Please try again.",
                            isError: true,
                          );
                        }
                      },
                    ),
                    // _settingsTile(
                    //   icon: Icons.notifications_outlined,
                    //   title: "Notification Settings",
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
              VSectionCard(
                title: "Support & Legal",
                icon: Icons.support_agent_outlined,
                padding: EdgeInsets.zero,
                child: _settingsTile(
                  icon: Icons.help_outline,
                  title: "Support",
                  onTap: () => _launchUrl(
                    'mailto:support@vconnect.com?subject=Support Request',
                  ),
                ),
              ),

              // --- LOGOUT BUTTON ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(
                    "Logout",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileHeaderCard(
    BuildContext context, {
    required User user,
    required String userEmail,
  }) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final name = data['name'] ?? user.displayName ?? "User Name";
        final dept = data['dept'] as String?;
        final customId = data['customId'] as String?;
        final photoUrl = data['photoUrl'] as String? ?? user.photoURL;

        return VSectionCard(
          accent: AppColors.primary,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            child: Row(
              children: [
                VAvatar(name: name, photoUrl: photoUrl, radius: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dept != null && dept.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dept,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.maroon,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customId != null && customId.isNotEmpty)
                        Text(
                          'ID: $customId',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}
