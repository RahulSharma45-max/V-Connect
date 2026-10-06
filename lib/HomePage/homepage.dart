import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide NavigationBar;
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/Calendar/calendar.dart';
import 'package:v_connect/Chat/chat_home_page.dart';
import 'package:v_connect/HomePage/navigation_bar.dart';
import 'package:v_connect/LoginPage/login_page.dart';
import 'package:v_connect/Profile/edit_profile.dart';
import 'package:v_connect/Profile/profile.dart';
import 'package:v_connect/Search/search_page.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';
import 'package:photo_view/photo_view.dart';

class Homepage extends StatefulWidget {
  User? user;
  Homepage({super.key, required this.user});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  String name = "";
  String dept = "";
  String customId = "";
  String? photoUrl;
  bool isPresent = false; // true = Present, false = Absent

  String? timetableUrl;

  /// How many upcoming events the dashboard lists before linking to the calendar.
  static const int _upcomingPreviewCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchUserData();
    fetchTimetable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ Toggle status between Present and Absent
  Future<void> toggleStatus() async {
    if (widget.user == null) return;

    bool newStatus = !isPresent;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user!.uid)
          .update({
            'isPresent': newStatus,
            'lastStatusUpdate': FieldValue.serverTimestamp(),
          });

      setState(() {
        isPresent = newStatus;
      });
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  Future<void> fetchUserData() async {
    if (widget.user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          name = data?['name'] ?? "";
          dept = data?['dept'] ?? "";
          customId = data?['customId'] ?? "";
          photoUrl = data?['photoUrl'];
          isPresent = data?['isPresent'] ?? false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  /// ✅ Stream for TODAY events
  Stream<List<Map<String, dynamic>>> streamTodayEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime todayEnd = todayStart.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThan: Timestamp.fromDate(todayEnd))
        .orderBy('date')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final d = doc.data();
            return {
              "id": doc.id,
              "title": d["title"],
              "time": d["time"],
              "date": (d["date"] as Timestamp).toDate(),
            };
          }).toList();
        });
  }

  /// ✅ Stream for FUTURE events
  Stream<List<Map<String, dynamic>>> streamFutureEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
        )
        .orderBy('date')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final d = doc.data();
            return {
              "id": doc.id,
              "title": d["title"],
              "time": d["time"],
              "date": (d["date"] as Timestamp).toDate(),
            };
          }).toList();
        });
  }

  /// ✅ Load timetable
  Future<void> fetchTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?["timetableUrl"] != null) {
      setState(() {
        timetableUrl = doc.data()?["timetableUrl"];
      });
    }
  }

  /// ✅ Convert Google Drive sharing link to direct link
  String? convertGoogleDriveLink(String link) {
    try {
      RegExp regExp = RegExp(r'(?:id=|\/d\/|\/file\/d\/)([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(link);

      if (match != null && match.groupCount >= 1) {
        String fileId = match.group(1)!;
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    } catch (e) {
      print("Error converting link: $e");
    }
    return null;
  }

  /// ✅ Upload timetable via Google Drive link
  Future<void> uploadTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController linkController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.link, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                "Google Drive Link",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: linkController,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: const InputDecoration(
              hintText: "Paste the shared timetable link here",
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () async {
                if (linkController.text.isNotEmpty) {
                  final convertedUrl = convertGoogleDriveLink(
                    linkController.text,
                  );

                  if (convertedUrl != null) {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .update({"timetableUrl": convertedUrl});

                    setState(() {
                      timetableUrl = convertedUrl;
                    });

                    Navigator.pop(context);
                  } else {
                    showVSnackBar(
                      context,
                      "Invalid Google Drive link",
                      isError: true,
                    );
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Show timetable in zoomable popup
  void _showTimetablePopup() {
    if (timetableUrl == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(timetableUrl!),
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

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _onQuickLink(String value) {
    switch (value) {
      case 'timetable':
        uploadTimetable();
        break;
      case 'events':
        _open(const CalendarPage());
        break;
      case 'messages':
        _open(const ChatHomePage());
        break;
      case 'edit_profile':
        _open(const EditProfilePage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VAppBar(
        titleWidget: const VBrandMark(),
        titleSpacing: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Quick Links',
            onSelected: _onQuickLink,
            offset: const Offset(0, 44),
            itemBuilder: (context) => [
              _quickLinkItem('timetable', Icons.table_chart, 'Timetable link'),
              _quickLinkItem('events', Icons.event, 'Events calendar'),
              _quickLinkItem('messages', Icons.message_outlined, 'Messages'),
              _quickLinkItem(
                'edit_profile',
                Icons.edit_outlined,
                'Edit profile',
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.onPrimary.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quick Links',
                    style: GoogleFonts.inter(
                      color: AppColors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.onPrimary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      bottomNavigationBar: const NavigationBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchUserData();
          await fetchTimetable();
        },
        child: ListView(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          children: [
            _welcomeHeader(),
            const SizedBox(height: 18),
            _profileStatusCard(),
            _moduleGrid(),
            _eventsListSection(
              title: "Today's Events",
              icon: Icons.today,
              stream: streamTodayEvents(),
              emptyText: 'Nothing scheduled for today.',
            ),
            _eventsListSection(
              title: "Upcoming Events",
              icon: Icons.upcoming,
              stream: streamFutureEvents(),
              emptyText: 'No upcoming events.',
              limit: _upcomingPreviewCount,
            ),
            _timetableSection(),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _quickLinkItem(
    String value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _welcomeHeader() {
    final firstName = name.trim().isEmpty ? '' : name.trim().split(' ').first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            firstName.isEmpty ? 'Welcome to V-Connect' : 'Welcome, $firstName',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Messages, events, timetables and presence for your campus in one place.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ PROFILE CARD WITH PRESENCE TOGGLE
  Widget _profileStatusCard() {
    return VSectionCard(
      title: dept.isEmpty ? 'My Profile' : dept,
      icon: Icons.account_circle_outlined,
      accent: AppColors.maroon,
      child: Row(
        children: [
          VAvatar(name: name, photoUrl: photoUrl, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? '—' : name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customId.isEmpty ? '' : 'ID: $customId',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: toggleStatus,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: VStatusChip(
                    key: ValueKey(isPresent),
                    isPresent: isPresent,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to change',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moduleGrid() {
    final tiles = [
      VModuleTile(
        label: 'Search',
        icon: Icons.person_search,
        color: AppColors.accentBlue,
        onTap: () => _open(const SearchPage()),
      ),
      VModuleTile(
        label: 'Events',
        icon: Icons.event_note,
        color: AppColors.accentGold,
        onTap: () => _open(const CalendarPage()),
      ),
      VModuleTile(
        label: 'Messages',
        icon: Icons.forum_outlined,
        color: AppColors.accentGreen,
        onTap: () => _open(const ChatHomePage()),
      ),
      VModuleTile(
        label: 'Profile',
        icon: Icons.manage_accounts_outlined,
        color: AppColors.accentCyan,
        onTap: () => _open(const ProfilePage()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.0,
        children: tiles,
      ),
    );
  }

  /// ✅ Timetable Section
  Widget _timetableSection() {
    return VSectionCard(
      title: 'Time Table',
      icon: Icons.table_chart_outlined,
      trailing: VHeaderLink(
        label: timetableUrl == null ? 'Add link' : 'Replace',
        onTap: uploadTimetable,
      ),
      child: timetableUrl == null
          ? Column(
              children: [
                const VEmptyState(
                  icon: Icons.table_chart_outlined,
                  title: 'No Time Table Uploaded',
                  subtitle: 'Share it from Google Drive and paste the link.',
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: uploadTimetable,
                    icon: const Icon(Icons.link),
                    label: const Text("Add Google Drive Link"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: _showTimetablePopup,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppColors.surfaceAlt,
                      child: Image.network(
                        timetableUrl!,
                        height: 200,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 120,
                          child: VEmptyState(
                            icon: Icons.broken_image_outlined,
                            title: 'Could not load the timetable image',
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in,
                            color: AppColors.onPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to zoom',
                            style: GoogleFonts.inter(
                              color: AppColors.onPrimary,
                              fontSize: 12,
                            ),
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

  /// ✅ EVENTS LIST
  Widget _eventsListSection({
    required String title,
    required IconData icon,
    required Stream<List<Map<String, dynamic>>> stream,
    required String emptyText,
    int? limit,
  }) {
    return VSectionCard(
      title: title,
      icon: icon,
      trailing: VHeaderLink(
        label: 'More ...',
        onTap: () => _open(const CalendarPage()),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const VEmptyState(
              icon: Icons.error_outline,
              title: 'Could not load events',
            );
          }
          if (!snap.hasData && snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          var events = snap.data ?? const <Map<String, dynamic>>[];
          if (events.isEmpty) {
            return VEmptyState(icon: Icons.event_available, title: emptyText);
          }
          if (limit != null && events.length > limit) {
            events = events.sublist(0, limit);
          }

          return Column(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _eventRow(events[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _eventRow(Map<String, dynamic> e) {
    final DateTime date = e['date'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.maroon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e["title"] ?? '',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            "${e['time'] ?? ''} • ${date.day}/${date.month}/${date.year}",
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final email = widget.user?.email ?? '';
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: VAvatar(name: name, photoUrl: photoUrl, radius: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  name.isEmpty ? 'V-Connect' : name,
                  style: GoogleFonts.inter(
                    color: AppColors.onPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (dept.isNotEmpty)
                  Text(
                    dept,
                    style: GoogleFonts.inter(
                      color: AppColors.onPrimary.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      color: AppColors.onPrimary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(Icons.home_outlined, 'Dashboard', () {}),
                _drawerItem(
                  Icons.person_search_outlined,
                  'Search Faculty',
                  () => _open(const SearchPage()),
                ),
                _drawerItem(
                  Icons.event_note_outlined,
                  'Events Calendar',
                  () => _open(const CalendarPage()),
                ),
                _drawerItem(
                  Icons.forum_outlined,
                  'Messages',
                  () => _open(const ChatHomePage()),
                ),
                _drawerItem(
                  Icons.table_chart_outlined,
                  'Time Table',
                  timetableUrl == null ? uploadTimetable : _showTimetablePopup,
                ),
                const Divider(),
                _drawerItem(
                  Icons.manage_accounts_outlined,
                  'Profile & Settings',
                  () => _open(const ProfilePage()),
                ),
                _drawerItem(
                  Icons.logout,
                  'Logout',
                  _logout,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          const VFooter(),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = AppColors.textPrimary,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == AppColors.textPrimary ? AppColors.primary : color,
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
