import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  User? currentUser;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String _filterType = 'all';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Read currentUser inside initState so we get the fully-restored auth state.
    currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('[ChatHomePage] initState — currentUser uid: ${currentUser?.uid ?? "NULL"}');
    _fetchAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllUsers() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final users = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((user) => user['id'] != currentUser!.uid)
          .toList();
      if (mounted) setState(() => _allUsers = users);
    } catch (e) {
      if (mounted) _showSnackBar('Error fetching users: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    showVSnackBar(context, message, isError: isError);
  }

  Future<void> _navigateToChat(Map<String, dynamic> otherUser) async {
    final authUser = currentUser ?? FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      debugPrint('[ChatHomePage] _navigateToChat: currentUser is NULL');
      if (mounted) {
        _showSnackBar('You must be logged in to chat.', isError: true);
      }
      return;
    }
    currentUser = authUser;

    // Robust ID extraction: prefer 'id', fallback to 'uid'
    final String? rawOtherId =
        (otherUser['id'] != null && otherUser['id'].toString().isNotEmpty)
            ? otherUser['id'].toString()
            : ((otherUser['uid'] != null && otherUser['uid'].toString().isNotEmpty)
                ? otherUser['uid'].toString()
                : null);

    debugPrint('[ChatHomePage] _navigateToChat called with input: $otherUser');
    debugPrint('[ChatHomePage] Extracted rawOtherId: $rawOtherId');

    if (rawOtherId == null || rawOtherId.isEmpty) {
      debugPrint('[ChatHomePage] _navigateToChat ABORT: invalid recipient user ID');
      if (mounted) {
        _showSnackBar('Cannot start chat: Invalid user ID', isError: true);
      }
      return;
    }

    if (rawOtherId == authUser.uid) {
      debugPrint('[ChatHomePage] _navigateToChat ABORT: recipient is current user (${authUser.uid})');
      if (mounted) {
        _showSnackBar('Cannot start a chat with yourself', isError: true);
      }
      return;
    }

    final String otherUserId = rawOtherId;

    // Ensure preparedOtherUser map contains both 'id' and 'uid' for ChatPage compatibility
    final Map<String, dynamic> preparedOtherUser = Map<String, dynamic>.from(otherUser);
    preparedOtherUser['id'] = otherUserId;
    preparedOtherUser['uid'] = otherUserId;

    // Generate DM chatRoomId deterministically
    List<String> ids = [authUser.uid, otherUserId]..sort();
    final String chatRoomId = ids.join('_');

    debugPrint('[ChatHomePage] _navigateToChat — currentUser: ${authUser.uid}, otherUser: $otherUserId, chatRoomId: $chatRoomId');

    try {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId);

      debugPrint('[ChatHomePage] Checking Firestore doc: chats/$chatRoomId');
      final doc = await chatRef.get();

      if (doc.exists) {
        debugPrint('[ChatHomePage] Existing chat doc found for $chatRoomId. Resetting unread count.');
        await chatRef.update({
          'unreadCount.${authUser.uid}': 0,
        });
      } else {
        debugPrint('[ChatHomePage] Creating new chat doc at chats/$chatRoomId');
        await chatRef.set({
          'participants': [authUser.uid, otherUserId],
          'isGroup': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': 'Chat started',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': authUser.uid,
          'unreadCount': {
            authUser.uid: 0,
            otherUserId: 0,
          },
          'archivedBy': {
            authUser.uid: false,
            otherUserId: false,
          },
        });
        debugPrint('[ChatHomePage] New chat doc created successfully for $chatRoomId');
      }

      if (!mounted) {
        debugPrint('[ChatHomePage] Widget unmounted before Navigator.push');
        return;
      }

      debugPrint('[ChatHomePage] Pushing ChatPage for $chatRoomId');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatRoomId: chatRoomId,
            otherUser: preparedOtherUser,
            isGroup: false,
          ),
        ),
      );

      debugPrint('[ChatHomePage] Returned from ChatPage for $chatRoomId');

      if (mounted && _isSearching) {
        setState(() {
          _isSearching = false;
          _searchController.clear();
        });
      }
    } catch (e, st) {
      debugPrint('[ChatHomePage] *** EXCEPTION in _navigateToChat ***');
      debugPrint('[ChatHomePage] Exception: $e');
      debugPrint('[ChatHomePage] StackTrace: $st');

      if (mounted) {
        _showSnackBar('Could not open chat: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _unarchiveChat(String chatId) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'archivedBy.${currentUser!.uid}': false,
    });
    if (mounted) _showSnackBar('Chat restored.');
  }

  Future<void> _archiveChat(String chatId) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'archivedBy.${currentUser!.uid}': true,
    });
    if (mounted) _showSnackBar('Chat archived.');
  }

  Future<bool> _confirmDeleteChat(
    String chatId,
    bool isGroup,
    String? createdBy,
    String chatName,
  ) async {
    if (isGroup && createdBy != currentUser!.uid) {
      _showSnackBar(
        'Only the group creator can delete the group.',
        isError: true,
      );
      return false;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Group?',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete the group for all members. This action cannot be undone.',
          style: GoogleFonts.inter(
            color: AppColors.ink.withOpacity(0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.ink.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final msgs = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();
        for (var doc in msgs.docs) {
          await doc.reference.delete();
        }
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .delete();
        if (mounted) _showSnackBar('Group deleted');
        return true;
      } catch (e) {
        if (mounted) _showSnackBar('Error: $e', isError: true);
        return false;
      }
    }
    return false;
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const VSheetHandle(),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.group_add,
                  color: AppColors.accentGreen,
                  size: 24,
                ),
              ),
              title: Text(
                'New Group',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Create a group with multiple people',
                style: GoogleFonts.inter(
                  color: AppColors.ink.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToGroupChat();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToGroupChat() {
    final groupNameController = TextEditingController();
    final memberSearchController = TextEditingController();
    final List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredUsers = memberSearchController.text.isEmpty
              ? _allUsers
              : _allUsers.where((user) {
                  final query = memberSearchController.text.toLowerCase();
                  return (user['name'] as String? ?? '').toLowerCase().contains(
                        query,
                      ) ||
                      (user['email'] as String? ?? '').toLowerCase().contains(
                        query,
                      );
                }).toList();

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: AppColors.accentGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Group',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter group name',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.ink.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.ink.withOpacity(0.1),
                      prefixIcon: Icon(
                        Icons.people,
                        color: AppColors.ink.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: memberSearchController,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    onChanged: (v) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.ink.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.ink.withOpacity(0.1),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.ink.withOpacity(0.7),
                      ),
                      suffixIcon: memberSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.ink.withOpacity(0.7),
                              ),
                              onPressed: () {
                                memberSearchController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedMembers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedMembers.length} member${selectedMembers.length > 1 ? 's' : ''} selected',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : filteredUsers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: AppColors.ink.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No members found',
                                      style: GoogleFonts.inter(
                                        color: AppColors.ink.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = selectedMembers.contains(
                                  user['id'],
                                );
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    clipBehavior: Clip.antiAlias,
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (v) => setDialogState(() {
                                        if (v == true) {
                                          selectedMembers.add(user['id']);
                                        } else {
                                          selectedMembers.remove(user['id']);
                                        }
                                      }),
                                      title: Text(
                                        user['name'] ?? 'No Name',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        user['email'] ?? '',
                                        style: GoogleFonts.inter(
                                          color: AppColors.ink.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                      secondary: CircleAvatar(
                                        backgroundColor:
                                            AppColors.primary.withOpacity(0.12),
                                        child: ClipOval(
                                          child: user['photoUrl'] is String &&
                                                  (user['photoUrl'] as String)
                                                      .isNotEmpty
                                              ? Image.network(
                                                  user['photoUrl'],
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Center(
                                                      child: Text(
                                                        (user['name'] ??
                                                                'U')[0]
                                                            .toUpperCase(),
                                                        style: GoogleFonts.inter(
                                                          color: AppColors.textPrimary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Text(
                                                  (user['name'] ?? 'U')[0]
                                                      .toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    color: AppColors.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      activeColor: AppColors.primary,
                                      checkColor: AppColors.onPrimary,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppColors.ink.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (groupNameController.text.trim().isEmpty) {
                    _showSnackBar('Enter group name', isError: true);
                    return;
                  }
                  if (selectedMembers.isEmpty) {
                    _showSnackBar('Select at least one member', isError: true);
                    return;
                  }
                  Navigator.pop(context);
                  await _createGroup(
                    groupNameController.text.trim(),
                    selectedMembers,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Create',
                  style: GoogleFonts.inter(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createGroup(String groupName, List<String> memberIds) async {
    if (currentUser == null) return;
    final allParticipantIds = [currentUser!.uid, ...memberIds];
    try {
      await FirebaseFirestore.instance.collection('chats').add({
        'groupName': groupName,
        'participants': allParticipantIds,
        'isGroup': true,
        'createdBy': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Group created',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
        'unreadCount': {for (var id in allParticipantIds) id: 0},
        'archivedBy': {for (var id in allParticipantIds) id: false},
      });
      if (mounted) _showSnackBar('Group "$groupName" created!');
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  void _navigateToGroupChatPage(
    String groupId,
    String groupName,
    List<dynamic> participants,
  ) {
    FirebaseFirestore.instance.collection('chats').doc(groupId).update({
      'unreadCount.${currentUser!.uid}': 0,
    });
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
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildChatsList() {
    if (currentUser == null) {
      return Center(
        child: Text(
          "Please log in.",
          style: GoogleFonts.inter(color: AppColors.ink.withOpacity(0.6)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser!.uid)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          final err = snapshot.error;
          final st = snapshot.stackTrace;
          debugPrint('[ChatHomePage] *** Firestore error ***');
          debugPrint('[ChatHomePage] currentUser uid: ${currentUser?.uid ?? "NULL"}');
          debugPrint('[ChatHomePage] error type: ${err.runtimeType}');
          debugPrint('[ChatHomePage] error: $err');
          if (st != null) debugPrint('[ChatHomePage] stackTrace: $st');
          // Show a concise message to user but full detail in console.
          final errStr = err?.toString() ?? 'Unknown error';
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'Error loading chats',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    errStr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.danger, fontSize: 11),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final isArchived =
              (data['archivedBy']
                  as Map<String, dynamic>?)?[currentUser!.uid] ??
              false;

          if (_filterType == 'archived') return isArchived;
          if (isArchived) return false;

          final bool isGroup = data['isGroup'] ?? false;
          switch (_filterType) {
            case 'unread':
              final unread =
                  ((data['unreadCount']
                      as Map<String, dynamic>?)?[currentUser!.uid] ??
                  0);
              return unread > 0;
            case 'groups':
              return isGroup;
            case 'personal':
              return !isGroup;
            case 'all':
            default:
              return true;
          }
        }).toList();

        final activeChats = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isGroup = data['isGroup'] ?? false;
          if (isGroup) return true;
          return data['lastMessage'] != 'Chat started';
        }).toList();

        if (activeChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _filterType == 'all'
                      ? Icons.chat_bubble_outline
                      : Icons.filter_list_off,
                  size: 80,
                  color: AppColors.ink.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  "No conversations yet",
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    "Tap the search icon to find users and start a new chat.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.ink.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
          itemCount: activeChats.length,
          itemBuilder: (context, index) => _ChatListItem(
            key: ValueKey(activeChats[index].id),
            chatDoc: activeChats[index],
            currentUser: currentUser!,
            onUserTap: _navigateToChat,
            onGroupTap: _navigateToGroupChatPage,
            onConfirmDelete: _confirmDeleteChat,
            onUnarchive: _unarchiveChat,
            onArchive: _archiveChat,
          ),
        );
      },
    );
  }

  Widget _buildUserSearchList(String searchQuery) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final filteredUsers = _allUsers.where((user) {
      final query = searchQuery.toLowerCase();
      return (user['name'] as String? ?? '').toLowerCase().contains(query) ||
          (user['email'] as String? ?? '').toLowerCase().contains(query);
    }).toList();

    if (filteredUsers.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 48,
                color: AppColors.ink.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No users found',
                style: GoogleFonts.inter(color: AppColors.ink.withOpacity(0.7)),
              ),
              Text(
                'Try a different search term',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppColors.surface,
            boxShadow: vCardShadow,
          ),
          child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => _navigateToChat(user),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: ClipOval(
                child: user['photoUrl'] is String &&
                        (user['photoUrl'] as String).isNotEmpty
                    ? Image.network(
                        user['photoUrl'] as String,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              (user['name'] ?? 'U')[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          (user['name'] ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            title: Text(
              user['name'] ?? 'No Name',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              user['email'] ?? '',
              style: GoogleFonts.inter(
                color: AppColors.ink.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.ink.withOpacity(0.5),
            ),
          ),
        ),

        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _filterType = value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.35),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? AppColors.onPrimary : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = _isSearching
        ? 'Search Users'
        : (_filterType == 'archived' ? 'Archived Chats' : 'Messages');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VAppBar(
        leading: IconButton(
          icon: Icon(
            _isSearching || _filterType == 'archived'
                ? Icons.close
                : Icons.arrow_back,
          ),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            } else if (_filterType == 'archived') {
              setState(() {
                _filterType = 'all';
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: appBarTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'archived') {
                setState(() {
                  _filterType = 'archived';
                  _isSearching = false;
                  _searchController.clear();
                });
              } else if (value == 'refresh') {
                setState(() {});
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Refresh',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    const Icon(
                      Icons.archive_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Archived Chats',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            )
          else
            Container(
              height: 52,
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Unread', 'unread'),
                  _buildFilterChip('Personal', 'personal'),
                  _buildFilterChip('Groups', 'groups'),
                ],
              ),
            ),
          Expanded(
            child: _isSearching
                ? _buildUserSearchList(_searchController.text)
                : _buildChatsList(),
          ),
        ],
      ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton(
              onPressed: _showNewChatOptions,
              tooltip: 'New chat',
              child: const Icon(Icons.add_comment_outlined),
            ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final DocumentSnapshot chatDoc;
  final User currentUser;
  final Function(Map<String, dynamic>) onUserTap;
  final Function(String, String, List<dynamic>) onGroupTap;
  final Future<bool> Function(String, bool, String?, String) onConfirmDelete;
  final void Function(String) onUnarchive;
  final void Function(String) onArchive;

  const _ChatListItem({
    required Key key,
    required this.chatDoc,
    required this.currentUser,
    required this.onUserTap,
    required this.onGroupTap,
    required this.onConfirmDelete,
    required this.onUnarchive,
    required this.onArchive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final bool isGroup = chatData['isGroup'] ?? false;
    final int unreadCount =
        (chatData['unreadCount'] as Map<String, dynamic>?)?[currentUser.uid] ??
        0;
    final bool isArchived =
        (chatData['archivedBy'] as Map<String, dynamic>?)?[currentUser.uid] ??
        false;

    final otherUserId = !isGroup && (chatData['participants'] as List?) != null
        ? (chatData['participants'] as List).firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => '',
          )
        : '';

    if (!isGroup && otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Dismissible(
          key: key!,
          background: Container(
            decoration: BoxDecoration(
              color: isArchived ? AppColors.primary : AppColors.success,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Icon(
              isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: AppColors.onPrimary,
            ),
          ),
          // MODIFIED: Secondary background for left-swipe is now only for groups.
          secondaryBackground: (!isArchived && isGroup)
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.onPrimary,
                  ),
                )
              : Container(
                  color: Colors.transparent,
                ), // Disables for personal chats
          // MODIFIED: This function decides whether a swipe is allowed to complete.
          confirmDismiss: (direction) async {
            // --- SWIPE LEFT (DELETE) ---
            if (direction == DismissDirection.endToStart) {
              // Only allow left-swiping for groups that are not archived.
              if (isGroup && !isArchived) {
                final chatName = chatData['groupName'] ?? 'this group';
                final createdBy = chatData['createdBy'] as String?;
                return await onConfirmDelete(
                  chatDoc.id,
                  isGroup,
                  createdBy,
                  chatName,
                );
              } else {
                // Disallow left swipe for personal chats or any archived chats.
                return false;
              }
            }
            // --- SWIPE RIGHT (ARCHIVE/UNARCHIVE) ---
            else if (direction == DismissDirection.startToEnd) {
              return true;
            }
            return false;
          },
          // MODIFIED: This function is called after a swipe is successfully completed.
          onDismissed: (direction) {
            // The left-swipe action for groups is handled by `onConfirmDelete`.
            // This now only needs to handle the right-swipe action.
            if (direction == DismissDirection.startToEnd) {
              if (isArchived) {
                onUnarchive(chatDoc.id);
              } else {
                onArchive(chatDoc.id);
              }
            }
          },
          child: _buildContent(
            context,
            chatData,
            isGroup,
            otherUserId,
            unreadCount,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> chatData,
    bool isGroup,
    String otherUserId,
    int unreadCount,
  ) {
    final Timestamp? timestamp = chatData['lastMessageTimestamp'];
    final itemBackgroundColor = unreadCount > 0
        ? Color.alphaBlend(
            AppColors.primary.withOpacity(0.06),
            AppColors.surface,
          )
        : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: itemBackgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: unreadCount > 0 ? AppColors.primary : AppColors.border,
            width: 3,
          ),
        ),
        boxShadow: vCardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(
          context,
          isGroup,
          otherUserId,
          unreadCount,
          itemBackgroundColor,
        ),
        title: StreamBuilder<String>(
          stream: _getChatNameStream(isGroup, chatData, otherUserId),
          builder: (context, snapshot) => Text(
            snapshot.data ?? (isGroup ? "Group" : "Chat"),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timestamp != null)
              Text(
                _formatTimestamp(timestamp),
                style: GoogleFonts.inter(
                  color: unreadCount > 0
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: GoogleFonts.inter(
                      color: AppColors.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onTap: () async {
          if (isGroup) {
            onGroupTap(
              chatDoc.id,
              chatData['groupName'] ?? 'Group',
              chatData['participants'],
            );
          } else {
            try {
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get();
              if (doc.exists && doc.data() != null) {
                onUserTap({'id': otherUserId, ...doc.data()!});
              } else {
                onUserTap({'id': otherUserId, 'name': 'User'});
              }
            } catch (e) {
              debugPrint('[ChatListItem] Error fetching user profile for $otherUserId: $e');
              onUserTap({'id': otherUserId, 'name': 'User'});
            }
          }
        },
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    bool isGroup,
    String otherUserId,
    int unreadCount,
    Color itemBackgroundColor,
  ) {
    Widget avatarWidget;

    if (isGroup) {
      avatarWidget = CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.accentGreen,
        child: const Icon(Icons.group, color: AppColors.onPrimary, size: 28),
      );
    } else {
      avatarWidget = StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
            return CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.ink.withOpacity(0.1),
            );
          }
          final otherUserData =
              userSnapshot.data!.data() as Map<String, dynamic>;
          final photoUrl = otherUserData['photoUrl'];
          final name =
              otherUserData['name'] ?? otherUserData['username'] ?? 'U';

          return CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: ClipOval(
              child: photoUrl != null && (photoUrl as String).isNotEmpty
                  ? Image.network(
                      photoUrl.toString(),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
          );

        },
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWidget,
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: itemBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) return DateFormat('h:mm a').format(date);
    if (difference.inDays == 1) return 'Yesterday';
    return DateFormat('MM/dd/yy').format(date);
  }

  Stream<String> _getChatNameStream(
    bool isGroup,
    Map<String, dynamic> chatData,
    String userId,
  ) {
    if (isGroup) return Stream.value(chatData['groupName'] ?? 'Unnamed Group');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return 'Unknown User';
          final data = doc.data();
          return data?['name'] ?? data?['username'] ?? 'Unknown User';
        });
  }
}
