import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:v_connect/Search/user_details_popup.dart'; // Verify path

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
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF111111), Colors.black],
          ),
        ),
        // MODIFICATION: SafeArea ensures the UI avoids notches and system bars.
        child: SafeArea(
          child: Column(
            children: [
              // MODIFICATION: Combined header with back button and search bar.
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search...",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            suffixIcon: hasSearchQuery
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : hasSearchQuery
                    ? _buildSearchResults()
                    : _buildSearchHistory(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Search Results",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "${_searchResults.length} found",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "No users found.",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent Searches",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_recentSearchQueries.isEmpty)
                      Text(
                        "Your search history is empty.",
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _recentSearchQueries.map((query) {
                          return GestureDetector(
                            onTap: () {
                              final tappedUser = _allUsers.firstWhere(
                                (user) => user['id'] == query['id'],
                                orElse: () => <String, dynamic>{},
                              );
                              if (tappedUser.isNotEmpty) {
                                _showUserDetailsPopup(tappedUser);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "This user could not be found.",
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    query['name'] ?? 'Unknown',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeSearchQuery(query),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_recentSearchQueries.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextButton(
                onPressed: _clearSearchHistory,
                child: Text(
                  "Clear search history",
                  style: GoogleFonts.inter(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserListTile(Map<String, dynamic> user) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.1),
        onTap: () => _showUserDetailsPopup(user),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.1),
                backgroundImage: user['photoUrl'] != null
                    ? NetworkImage(user['photoUrl'])
                    : null,
                child: user['photoUrl'] == null
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'No Name',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${user['dept'] ?? 'N/A'} • ID: ${user['customId'] ?? 'N/A'}",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
