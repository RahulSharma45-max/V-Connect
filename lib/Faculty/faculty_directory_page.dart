import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/Faculty/faculty_info.dart';
import 'package:v_connect/Faculty/faculty_profile_page.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

/// Live list of every faculty member, grouped by department, with search,
/// a department filter and a "present now" filter.
class FacultyDirectoryPage extends StatefulWidget {
  const FacultyDirectoryPage({super.key});

  @override
  State<FacultyDirectoryPage> createState() => _FacultyDirectoryPageState();
}

class _FacultyDirectoryPageState extends State<FacultyDirectoryPage> {
  static const String _otherDept = 'Other';

  final _searchController = TextEditingController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  String? _dept; // null = all departments
  bool _presentOnly = false;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection('users').snapshots();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProfile(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FacultyProfilePage(facultyId: id, initialData: {'id': id, ...data}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VAppBar(
        title: 'Faculty Directory',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search name, department, ID or subject',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const VEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load the faculty directory.',
              subtitle: 'Check your connection and try again.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!.docs
              .map((doc) => (doc, FacultyInfo.fromMap(doc.id, doc.data())))
              .where((entry) => entry.$2.name.isNotEmpty)
              .toList();

          final departments =
              all
                  .map((e) => e.$2.dept)
                  .where((d) => d.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          // Drop a stale department filter if that department disappeared.
          final selectedDept = departments.contains(_dept) ? _dept : null;

          final visible =
              all.where((e) {
                final f = e.$2;
                if (selectedDept != null && f.dept != selectedDept) {
                  return false;
                }
                if (_presentOnly && !f.isPresent) return false;
                return f.matches(query);
              }).toList()..sort(
                (a, b) =>
                    a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase()),
              );

          final presentCount = visible.where((e) => e.$2.isPresent).length;

          // Group by department, keeping departments alphabetical and the
          // "no department" bucket last.
          final groups = <String, List<(DocumentSnapshot, FacultyInfo)>>{};
          for (final entry in visible) {
            final key = entry.$2.dept.isEmpty ? _otherDept : entry.$2.dept;
            groups.putIfAbsent(key, () => []).add(entry);
          }
          final groupKeys = groups.keys.toList()
            ..sort((a, b) {
              if (a == _otherDept) return 1;
              if (b == _otherDept) return -1;
              return a.compareTo(b);
            });

          return Column(
            children: [
              _filterBar(departments, selectedDept),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${visible.length} faculty',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '  ·  $presentCount present',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Align(
                        alignment: Alignment.topCenter,
                        child: VEmptyState(
                          icon: Icons.person_search_outlined,
                          title: 'No faculty match these filters.',
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          for (final key in groupKeys) ...[
                            _deptHeader(key, groups[key]!.length),
                            for (final entry in groups[key]!)
                              _facultyTile(entry.$1, entry.$2),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterBar(List<String> departments, String? selectedDept) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedDept,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more, color: AppColors.primary),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownColor: AppColors.surface,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All departments'),
                    ),
                    for (final dept in departments)
                      DropdownMenuItem<String?>(
                        value: dept,
                        child: Text(dept, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _dept = value),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => setState(() => _presentOnly = !_presentOnly),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _presentOnly ? AppColors.success : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _presentOnly
                      ? AppColors.success
                      : AppColors.success.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _presentOnly ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: _presentOnly
                        ? AppColors.onPrimary
                        : AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Present now',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _presentOnly
                          ? AppColors.onPrimary
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deptHeader(String dept, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dept.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.maroon,
              ),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _facultyTile(DocumentSnapshot doc, FacultyInfo faculty) {
    final isMe = FirebaseAuth.instance.currentUser?.uid == faculty.id;
    final subtitle = [
      if (faculty.designation.isNotEmpty) faculty.designation,
      if (faculty.customId.isNotEmpty) 'ID: ${faculty.customId}',
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: faculty.isPresent ? AppColors.success : AppColors.border,
            width: 3,
          ),
        ),
        boxShadow: vCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfile(doc.id, doc.data() as Map<String, dynamic>),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                VAvatar(
                  name: faculty.name,
                  photoUrl: faculty.photoUrl,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              faculty.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(You)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                VStatusChip(isPresent: faculty.isPresent, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
