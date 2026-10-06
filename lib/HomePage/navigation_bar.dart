import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/Calendar/calendar.dart';
import 'package:v_connect/Profile/profile.dart';
import 'package:v_connect/Search/search_page.dart';
import 'package:v_connect/Chat/chat_home_page.dart';
import 'package:v_connect/theme/app_theme.dart';

/// Bottom bar on the dashboard. "Home" is the current page; every other
/// item pushes its screen on top so the back button returns here.
class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  void _onItemTapped(BuildContext context, int index) {
    final Widget? page = switch (index) {
      1 => const SearchPage(),
      2 => const CalendarPage(),
      3 => const ChatHomePage(),
      4 => const ProfilePage(),
      _ => null,
    };
    if (page == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _buildItem(context, Icons.home_rounded, 'Home', 0),
              _buildItem(context, Icons.search, 'Search', 1),
              _buildItem(context, Icons.calendar_today, 'Events', 2),
              _buildItem(context, Icons.message, 'Messages', 3),
              _buildItem(context, Icons.person, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final bool isSelected = index == 0;
    final color = isSelected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(context, index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
