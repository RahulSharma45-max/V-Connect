import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v_connect/Chat/chat_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _selectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((user) => user['id'] != currentUser.uid)
        .toList();
    if (mounted)
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
  }

  void _toggleUserSelection(Map<String, dynamic> user) {
    setState(() {
      if (_selectedUsers.any((selected) => selected['id'] == user['id'])) {
        _selectedUsers.removeWhere((selected) => selected['id'] == user['id']);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name.")),
      );
      return;
    }
    if (_selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least two members for the group."),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> participantIds = [
      currentUser.uid,
      ..._selectedUsers.map((user) => user['id'] as String),
    ];

    DocumentReference groupChatRef = await FirebaseFirestore.instance
        .collection('chats')
        .add({
          'participants': participantIds,
          'isGroup': true,
          'groupName': groupName,
          'groupAdmin': currentUser.uid,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessage':
              '${currentUser.displayName ?? 'Someone'} created the group.',
        });

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: groupChatRef.id,
          otherUser: {
            'id': groupChatRef.id,
            'name': groupName,
            'isGroup': true,
          },
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "New Group",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _createGroup,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _groupNameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Group Name",
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select Members (${_selectedUsers.length})",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      final isSelected = _selectedUsers.any(
                        (selected) => selected['id'] == user['id'],
                      );
                      return CheckboxListTile(
                        title: Text(
                          user['name'] ?? 'No Name',
                          style: const TextStyle(color: Colors.white),
                        ),
                        secondary: CircleAvatar(
                          backgroundImage: user['photoUrl'] != null
                              ? NetworkImage(user['photoUrl'])
                              : null,
                        ),
                        value: isSelected,
                        onChanged: (selected) => _toggleUserSelection(user),
                        activeColor: Colors.lightBlue.shade300,
                        checkColor: Colors.black,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
