import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:v_connect/Search/user_details_popup.dart'; // Verify path
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearchQueries = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(() {
      setState(() {}); // To update the UI for the clear button
      _filterUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([_fetchAllUsers(), _fetchRecentSearchQueries()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchAllUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      _allUsers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print("Error fetching all users: $e");
    }
  }

  Future<void> _fetchRecentSearchQueries() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('searchHistory')) {
        final historyData = doc.data()!['searchHistory'] as List;
        _recentSearchQueries = historyData
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      print("Error fetching search history: $e");
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _allUsers.where((user) {
        final name = (user['name'] as String? ?? '').toLowerCase();
        final dept = (user['dept'] as String? ?? '').toLowerCase();
        final customId = (user['customId'] as String? ?? '').toLowerCase();
        return name.contains(query) ||
            dept.contains(query) ||
            customId.contains(query);
      }).toList();
    }
  }

  Future<void> _saveSearchQuery(Map<String, dynamic> userToSave) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null ||
        userToSave['id'] == null ||
        userToSave['name'] == null)
      return;

    final newSearchItem = {'id': userToSave['id'], 'name': userToSave['name']};

    setState(() {
      _recentSearchQueries.removeWhere(
        (item) => item['id'] == newSearchItem['id'],
      );
      _recentSearchQueries.insert(0, newSearchItem);
      if (_recentSearchQueries.length > 15) {
        _recentSearchQueries = _recentSearchQueries.sublist(0, 15);
      }
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({'searchHistory': _recentSearchQueries}, SetOptions(merge: true));
  }

  Future<void> _removeSearchQuery(Map<String, dynamic> query) async {
    setState(() {
      _recentSearchQueries.removeWhere((item) => item['id'] == query['id']);
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'searchHistory': _recentSearchQueries});
  }

  Future<void> _clearSearchHistory() async {
    setState(() => _recentSearchQueries = []);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'searchHistory': []});
  }

  void _showUserDetailsPopup(Map<String, dynamic> userData) {
    _saveSearchQuery(userData);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailsPopup(userData: userData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSearchQuery = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VAppBar(
        title: 'Search Faculty',
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
                hintText: "Search by name, department or ID",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasSearchQuery
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasSearchQuery
          ? _buildSearchResults()
          : _buildSearchHistory(),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Search Results",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.maroon,
                ),
              ),
              Text(
                "${_searchResults.length} found",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? const Align(
                  alignment: Alignment.topCenter,
                  child: VEmptyState(
                    icon: Icons.person_off_outlined,
                    title: "No users found.",
                    subtitle: 'Try a different name, department or ID.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) =>
                        _buildUserListTile(_searchResults[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        VSectionCard(
          title: "Recent Searches",
          icon: Icons.history,
          trailing: _recentSearchQueries.isEmpty
              ? null
              : VHeaderLink(
                  label: 'Clear',
                  color: AppColors.danger,
                  onTap: _clearSearchHistory,
                ),
          child: _recentSearchQueries.isEmpty
              ? const VEmptyState(
                  icon: Icons.manage_search,
                  title: "Your search history is empty.",
                  subtitle: 'Faculty you look up will appear here.',
                )
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _recentSearchQueries.map((query) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final tappedUser = _allUsers.firstWhere(
                          (user) => user['id'] == query['id'],
                          orElse: () => <String, dynamic>{},
                        );
                        if (tappedUser.isNotEmpty) {
                          _showUserDetailsPopup(tappedUser);
                        } else {
                          showVSnackBar(
                            context,
                            "This user could not be found.",
                            isError: true,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              query['name'] ?? 'Unknown',
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _removeSearchQuery(query),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildUserListTile(Map<String, dynamic> user) {
    final bool isPresent = user['isPresent'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
        boxShadow: vCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetailsPopup(user),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                VAvatar(
                  name: user['name'] ?? '',
                  photoUrl: user['photoUrl'],
                  radius: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'No Name',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${user['dept'] ?? 'N/A'} • ID: ${user['customId'] ?? 'N/A'}",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                VStatusChip(isPresent: isPresent, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
