import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v_connect/Chat/chat_page.dart';
import 'package:v_connect/Chat/direct_chat.dart';
import 'package:v_connect/Faculty/faculty_info.dart';
import 'package:v_connect/Faculty/timetable_viewer.dart';
import 'package:v_connect/Profile/edit_profile.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

/// Everything about one faculty member: identity and presence, contact
/// actions, profile details, communities, shared groups and timetable.
class FacultyProfilePage extends StatelessWidget {
  final String facultyId;

  /// Shown while the live document loads (e.g. the row the user tapped).
  final Map<String, dynamic>? initialData;

  const FacultyProfilePage({
    super.key,
    required this.facultyId,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwn = currentUid == facultyId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VAppBar(
        title: isOwn ? 'My Faculty Profile' : 'Faculty Profile',
        actions: [
          if (isOwn)
            IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditProfile(context),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(facultyId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? initialData;
          if (data == null) {
            if (snapshot.hasError) {
              return const VEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load this profile',
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return const VEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Faculty member not found',
            );
          }

          final faculty = FacultyInfo.fromMap(facultyId, data);
          return ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            children: [
              _HeaderCard(faculty: faculty, isOwn: isOwn),
              _QuickActions(faculty: faculty, isOwn: isOwn),
              _DetailsSection(faculty: faculty),
              _CommunitiesSection(facultyId: facultyId, isOwn: isOwn),
              if (!isOwn && currentUid != null)
                _CommonGroupsSection(
                  facultyId: facultyId,
                  currentUid: currentUid,
                ),
              _TimetableSection(faculty: faculty, isOwn: isOwn),
            ],
          );
        },
      ),
    );
  }
}

void _openEditProfile(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const EditProfilePage()),
  );
}

String _formatWhen(DateTime time) {
  final now = DateTime.now();
  final isToday =
      now.year == time.year && now.month == time.month && now.day == time.day;
  return isToday
      ? 'today at ${DateFormat('h:mm a').format(time)}'
      : DateFormat('d MMM, h:mm a').format(time);
}

// ---------------------------------------------------------------------------
// Header: avatar, name, designation, presence
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  final FacultyInfo faculty;
  final bool isOwn;

  const _HeaderCard({required this.faculty, required this.isOwn});

  Future<void> _togglePresence(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(faculty.id)
          .update({
            'isPresent': !faculty.isPresent,
            'lastStatusUpdate': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (context.mounted) {
        showVSnackBar(context, 'Could not update status: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusChip = VStatusChip(isPresent: faculty.isPresent);

    return VSectionCard(
      accent: AppColors.primary,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VAvatar(name: faculty.name, photoUrl: faculty.photoUrl, radius: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faculty.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (faculty.designation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    faculty.designation,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.maroon,
                    ),
                  ),
                ],
                if (faculty.dept.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    faculty.dept,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (isOwn)
                      InkWell(
                        onTap: () => _togglePresence(context),
                        borderRadius: BorderRadius.circular(20),
                        child: statusChip,
                      )
                    else
                      statusChip,
                    if (faculty.isOnline)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Active in app',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (faculty.lastStatusUpdate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Status updated ${_formatWhen(faculty.lastStatusUpdate!)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (isOwn)
                  Text(
                    'Tap your status to change it',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions: message / call / email / timetable
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  final FacultyInfo faculty;
  final bool isOwn;

  const _QuickActions({required this.faculty, required this.isOwn});

  Future<void> _openChat(BuildContext context) async {
    try {
      final chat = await ensureDirectChat(faculty.toChatUser());
      if (chat == null || !context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatPage(chatRoomId: chat.chatRoomId, otherUser: chat.otherUser),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showVSnackBar(context, 'Could not open chat: $e', isError: true);
      }
    }
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showVSnackBar(context, 'No app available to open this.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetable = directTimetableUrl(faculty.timetableUrl);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          isOwn
              ? _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppColors.accentGreen,
                  onTap: () => _openEditProfile(context),
                )
              : _ActionButton(
                  icon: Icons.forum_outlined,
                  label: 'Message',
                  color: AppColors.accentGreen,
                  onTap: () => _openChat(context),
                ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.call_outlined,
            label: 'Call',
            color: AppColors.accentBlue,
            onTap: faculty.phone.isEmpty
                ? null
                : () =>
                      _launch(context, Uri(scheme: 'tel', path: faculty.phone)),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.mail_outline,
            label: 'Email',
            color: AppColors.accentGold,
            onTap: faculty.email.isEmpty
                ? null
                : () => _launch(
                    context,
                    Uri(scheme: 'mailto', path: faculty.email),
                  ),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.table_chart_outlined,
            label: 'Timetable',
            color: AppColors.accentCyan,
            onTap: timetable == null
                ? null
                : () => showTimetableViewer(context, timetable),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tint = enabled ? color : AppColors.textMuted.withOpacity(0.5);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border(top: BorderSide(color: tint, width: 2)),
          boxShadow: vCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(icon, color: tint, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile details
// ---------------------------------------------------------------------------

class _DetailsSection extends StatelessWidget {
  final FacultyInfo faculty;

  const _DetailsSection({required this.faculty});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _DetailRow(Icons.badge_outlined, 'Employee ID', faculty.customId),
      _DetailRow(Icons.apartment_outlined, 'Department', faculty.dept),
      _DetailRow(Icons.work_outline, 'Designation', faculty.designation),
      _DetailRow(Icons.meeting_room_outlined, 'Cabin / Room', faculty.cabin),
      _DetailRow(
        Icons.school_outlined,
        'Specialization',
        faculty.specialization,
      ),
      _DetailRow(Icons.schedule_outlined, 'Office Hours', faculty.officeHours),
      _DetailRow(Icons.mail_outline, 'Email', faculty.email),
      _DetailRow(Icons.phone_outlined, 'Phone', faculty.phone),
    ];

    return VSectionCard(
      title: 'Faculty Information',
      icon: Icons.info_outline,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              hasValue ? value : 'Not provided',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Communities the faculty member belongs to
// ---------------------------------------------------------------------------

class _CommunitiesSection extends StatefulWidget {
  final String facultyId;
  final bool isOwn;

  const _CommunitiesSection({required this.facultyId, required this.isOwn});

  @override
  State<_CommunitiesSection> createState() => _CommunitiesSectionState();
}

class _CommunitiesSectionState extends State<_CommunitiesSection> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('communities')
        .where('members', arrayContains: widget.facultyId);
    // Security rules only let members read private communities, so for
    // someone else's profile ask for the public ones explicitly.
    if (!widget.isOwn) {
      query = query.where('isPublic', isEqualTo: true);
    }
    _stream = query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final sorted = [...docs]
          ..sort(
            (a, b) => (a.data()['name'] ?? '')
                .toString()
                .toLowerCase()
                .compareTo((b.data()['name'] ?? '').toString().toLowerCase()),
          );

        Widget body;
        if (snapshot.hasError) {
          debugPrint('[FacultyProfile] communities error: ${snapshot.error}');
          body = const VEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load communities right now.',
          );
        } else if (!snapshot.hasData) {
          body = const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (sorted.isEmpty) {
          body = VEmptyState(
            icon: Icons.groups_2_outlined,
            title: widget.isOwn
                ? 'You are not part of any communities yet.'
                : 'Not part of any public communities.',
          );
        } else {
          body = Column(
            children: [
              for (var i = 0; i < sorted.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _CommunityTile(
                  data: sorted[i].data(),
                  facultyId: widget.facultyId,
                ),
              ],
            ],
          );
        }

        return VSectionCard(
          title: 'Communities',
          icon: Icons.groups_2_outlined,
          accent: AppColors.accentGreen,
          trailing: snapshot.hasData && sorted.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CountPill(
                    count: sorted.length,
                    color: AppColors.accentGreen,
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              body,
              if (!widget.isOwn) ...[
                const SizedBox(height: 6),
                Text(
                  'Only public communities are listed. Private ones are visible to their members.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String facultyId;

  const _CommunityTile({required this.data, required this.facultyId});

  String get _name => (data['name'] ?? 'Unnamed community').toString();
  String get _description => (data['description'] ?? '').toString().trim();
  int get _memberCount => (data['members'] as List?)?.length ?? 0;
  bool get _isPublic => data['isPublic'] as bool? ?? true;
  bool get _isAdmin => data['adminId'] == facultyId;

  void _showDetails(BuildContext context) {
    final createdAt = data['createdAt'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            VAvatar(
              name: _name,
              photoUrl: data['photoUrl'] as String?,
              fallbackIcon: Icons.groups_2_outlined,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _name,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _description.isEmpty ? 'No description.' : _description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 6, runSpacing: 6, children: _tags()),
            if (createdAt is Timestamp) ...[
              const SizedBox(height: 10),
              Text(
                'Created ${DateFormat('d MMM y').format(createdAt.toDate())}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _tags() => [
    _Tag(
      '$_memberCount ${_memberCount == 1 ? 'member' : 'members'}',
      AppColors.textSecondary,
    ),
    _Tag(
      _isPublic ? 'Public' : 'Private',
      _isPublic ? AppColors.primary : AppColors.warning,
    ),
    if (_isAdmin) const _Tag('Admin', AppColors.maroon),
  ];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetails(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VAvatar(
              name: _name,
              photoUrl: data['photoUrl'] as String?,
              fallbackIcon: Icons.groups_2_outlined,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: _tags()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group chats shared with the signed-in user
// ---------------------------------------------------------------------------

class _CommonGroupsSection extends StatefulWidget {
  final String facultyId;
  final String currentUid;

  const _CommonGroupsSection({
    required this.facultyId,
    required this.currentUid,
  });

  @override
  State<_CommonGroupsSection> createState() => _CommonGroupsSectionState();
}

class _CommonGroupsSectionState extends State<_CommonGroupsSection> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    // Chat rules only allow listing chats you are in, so query your own
    // groups and keep the ones this faculty member is also in.
    _stream = FirebaseFirestore.instance
        .collection('chats')
        .where('isGroup', isEqualTo: true)
        .where('participants', arrayContains: widget.currentUid)
        .snapshots();
  }

  void _openGroup(
    BuildContext context,
    String groupId,
    Map<String, dynamic> data,
  ) {
    final participants = (data['participants'] as List?) ?? const [];
    final groupName = (data['groupName'] ?? 'Group').toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: groupId,
          otherUser: {
            'id': groupId,
            'name': groupName,
            'isGroup': true,
            'participants': participants,
          },
          isGroup: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        final shared = (snapshot.data?.docs ?? const [])
            .where(
              (doc) => ((doc.data()['participants'] as List?) ?? const [])
                  .contains(widget.facultyId),
            )
            .toList();

        Widget body;
        if (snapshot.hasError) {
          body = const VEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load groups right now.',
          );
        } else if (!snapshot.hasData) {
          body = const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (shared.isEmpty) {
          body = const VEmptyState(
            icon: Icons.group_outlined,
            title: 'No groups in common.',
          );
        } else {
          body = Column(
            children: [
              for (var i = 0; i < shared.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _groupTile(context, shared[i]),
              ],
            ],
          );
        }

        return VSectionCard(
          title: 'Groups in Common',
          icon: Icons.forum_outlined,
          accent: AppColors.primary,
          trailing: shared.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CountPill(
                    count: shared.length,
                    color: AppColors.primary,
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: body,
        );
      },
    );
  }

  Widget _groupTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final count = (data['participants'] as List?)?.length ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _openGroup(context, doc.id, data),
      leading: const CircleAvatar(
        backgroundColor: AppColors.accentGreen,
        child: Icon(Icons.group, color: AppColors.onPrimary, size: 20),
      ),
      title: Text(
        (data['groupName'] ?? 'Unnamed Group').toString(),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '$count member${count == 1 ? '' : 's'}',
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}

// ---------------------------------------------------------------------------
// Timetable
// ---------------------------------------------------------------------------

class _TimetableSection extends StatelessWidget {
  final FacultyInfo faculty;
  final bool isOwn;

  const _TimetableSection({required this.faculty, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final url = directTimetableUrl(faculty.timetableUrl);

    return VSectionCard(
      title: 'Time Table',
      icon: Icons.table_chart_outlined,
      child: url == null
          ? VEmptyState(
              icon: Icons.table_chart_outlined,
              title: 'No timetable uploaded',
              subtitle: isOwn
                  ? 'Add your Google Drive link from the dashboard.'
                  : null,
            )
          : GestureDetector(
              onTap: () => showTimetableViewer(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: double.infinity,
                  color: AppColors.surfaceAlt,
                  child: Image.network(
                    url,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const VEmptyState(
                      icon: Icons.broken_image_outlined,
                      title: 'Could not load the timetable image',
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small bits
// ---------------------------------------------------------------------------

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  final Color color;

  const _CountPill({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
