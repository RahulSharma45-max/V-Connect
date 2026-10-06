import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool pushNotifications = true;
  bool emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VAppBar(title: "Notifications"),
      body: Column(
        children: [
          const SizedBox(height: 16),
          VSectionCard(
            title: 'Preferences',
            icon: Icons.notifications_outlined,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _switchTile(
                  title: "Push Notifications",
                  subtitle: "Receive updates about your account and activity.",
                  value: pushNotifications,
                  onChanged: (val) => setState(() => pushNotifications = val),
                ),
                const Divider(height: 1),
                _switchTile(
                  title: "Email Notifications",
                  subtitle: "Receive marketing and feature update emails.",
                  value: emailNotifications,
                  onChanged: (val) => setState(() => emailNotifications = val),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // TODO: Implement logic to save these settings
                  Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      activeColor: AppColors.onPrimary,
      activeTrackColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
