import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

// Common Emojis
const List<String> kCommonEmojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😆',
  '😅',
  '😂',
  '🤣',
  '🙂',
  '🙃',
  '😉',
  '😊',
  '😇',
  '🥰',
  '😍',
  '🤩',
  '😘',
  '😗',
  '😚',
  '😙',
  '😋',
  '😛',
  '😜',
  '🤪',
  '🤨',
  '🧐',
  '🤓',
  '😎',
  '🥸',
  '🥳',
  '🤠',
  '🤡',
  '😏',
  '😒',
  '😞',
  '😔',
  '😟',
  '😕',
  '🙁',
  '☹️',
  '😣',
  '😖',
  '😫',
  '😩',
  '🥺',
  '😢',
  '😭',
  '😤',
  '😠',
  '😡',
  '🤬',
  '🤯',
  '😳',
  '🥵',
  '🥶',
  '😱',
  '😨',
  '😰',
  '😥',
  '😓',
  '🤗',
  '🤔',
  '🤭',
  '🤫',
  '🤥',
  '😶',
  '😐',
  '😑',
  '😬',
  '🙄',
  '😯',
  '😦',
  '😧',
  '😮',
  '😲',
  '🥱',
  '😴',
  '🤤',
  '😪',
  '😵',
  '🤐',
  '🥴',
  '🤢',
  '🤮',
  '🤧',
  '😷',
  '🤒',
  '🤕',
  '🤑',
  '🤠',
  '😈',
  '👿',
  '👹',
  '👺',
  '🤡',
  '💩',
  '👍',
  '👎',
  '👌',
  '✌️',
  '🤞',
  '🤟',
  '🤘',
  '🤙',
  '👈',
  '👉',
  '👆',
  '👇',
  '☝️',
  '✊',
  '🤛',
  '🤜',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🖤',
  '🤍',
  '💔',
  '❣️',
  '💕',
  '💞',
  '💓',
  '💗',
  '💖',
  '🔥',
  '💯',
  '✨',
  '🌟',
  '💫',
  '💥',
  '🌈',
  '☀️',
  '🌙',
  '⚡️',
];

// Message Model
class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final String? imageUrl;
  final bool isPinned;
  final bool isStarred;
  final bool isDeleted;
  final String? deletedBy;
  final bool isEdited;
  final DateTime? editedTimestamp;
  final List<String> reactions;
  final String? replyToId;
  final String? replyToText;
  final bool isForwarded;
  final String? forwardedFrom;
  final String? senderId;
  final String? forwardedBy;
  final String? forwardedByName;
  final String? senderName;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.imageUrl,
    this.isPinned = false,
    this.isStarred = false,
    this.isDeleted = false,
    this.deletedBy,
    this.isEdited = false,
    this.editedTimestamp,
    this.reactions = const [],
    this.replyToId,
    this.replyToText,
    this.isForwarded = false,
    this.forwardedFrom,
    this.senderId,
    this.forwardedBy,
    this.forwardedByName,
    this.senderName,
  });

  factory Message.fromMap(
    String id,
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    List<String> reactionsList = [];
    if (data['reactions'] != null) {
      try {
        if (data['reactions'] is List) {
          reactionsList = List<String>.from(data['reactions']);
        }
      } catch (e) {
        debugPrint('Error parsing reactions: $e');
      }
    }

    return Message(
      id: id,
      text: data['text']?.toString() ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSentByMe: data['senderId'] == currentUserId,
      imageUrl: data['imageUrl']?.toString(),
      isPinned: data['isPinned'] == true,
      isStarred: data['isStarred'] == true,
      isDeleted: data['isDeleted'] == true,
      deletedBy: data['deletedBy']?.toString(),
      isEdited: data['isEdited'] == true,
      editedTimestamp: (data['editedTimestamp'] as Timestamp?)?.toDate(),
      reactions: reactionsList,
      replyToId: data['replyToId']?.toString(),
      replyToText: data['replyToText']?.toString(),
      isForwarded: data['isForwarded'] == true,
      forwardedFrom: data['forwardedFrom']?.toString(),
      senderId: data['senderId']?.toString(),
      forwardedBy: data['forwardedBy']?.toString(),
      forwardedByName: data['forwardedByName']?.toString(),
      senderName: data['senderName']?.toString(),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final Map<String, dynamic> otherUser;
  final bool isGroup;

  const ChatPage({
    super.key,
    required this.chatRoomId,
    required this.otherUser,
    this.isGroup = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  bool _showSendButton = false;
  bool _showEmojiPicker = false;
  bool _isUploading = false;
  bool _showSearchBar = false;
  String _searchQuery = '';
  Message? _replyingTo;
  final Set<String> _selectedMessages = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageTextChanged);
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'isOnline': true, 'lastSeen': FieldValue.serverTimestamp()});
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
    }
    super.dispose();
  }

  void _onMessageTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_showSendButton != hasText) {
      setState(() => _showSendButton = hasText);
    }
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    if (currentUser == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId);

    _messageController.clear();
    if (mounted) {
      setState(() {
        _showSendButton = false;
        if (_replyingTo != null) {
          _replyingTo = null;
        }
      });
    }

    String? senderName;
    if (widget.isGroup) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      senderName = userDoc.data()?['name'] ?? 'Unknown';
    }

    final messageData = {
      'text': text,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isPinned': false,
      'isStarred': false,
      'isDeleted': false,
      'isEdited': false,
      'reactions': [],
      'isForwarded': false,
      if (widget.isGroup && senderName != null) 'senderName': senderName,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (_replyingTo != null) ...{
        'replyToId': _replyingTo!.id,
        'replyToText': _replyingTo!.text,
      },
    };

    try {
      await chatRef.collection('messages').add(messageData);

      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) return;
      final participants = List<String>.from(
        chatDoc.data()?['participants'] ?? [],
      );

      String lastMsg = text.isNotEmpty ? text : '📷 Photo';
      final Map<String, dynamic> updateData = {
        'lastMessage': lastMsg,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
      };

      for (final participantId in participants) {
        if (participantId != currentUser!.uid) {
          updateData['unreadCount.$participantId'] = FieldValue.increment(1);
        }
      }

      await chatRef.update(updateData);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error sending message: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (mounted) {
        setState(() => _isUploading = true);
      }

      String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.chatRoomId)
          .child(fileName);

      final bytes = await pickedFile.readAsBytes();

      UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(imageUrl: downloadUrl);

      if (mounted) {
        _showSnackBar('Image sent successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error uploading image: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _onEmojiSelected(String emoji) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _replyToMessage(Message message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _toggleMessageSelection(String messageId) {
    if (_selectedMessages.contains(messageId)) {
      _selectedMessages.remove(messageId);
      if (_selectedMessages.isEmpty) {
        setState(() => _isSelectionMode = false);
      } else {
        setState(() {});
      }
    } else {
      _selectedMessages.add(messageId);
      if (!_isSelectionMode) {
        setState(() => _isSelectionMode = true);
      } else {
        setState(() {});
      }
    }
  }

  void _cancelSelection() {
    _selectedMessages.clear();
    setState(() => _isSelectionMode = false);
  }

  void _forwardMessages() async {
    if (currentUser == null || !mounted || _selectedMessages.isEmpty) return;

    try {
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('isGroup', isEqualTo: true)
          .where('participants', arrayContains: currentUser!.uid)
          .get();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUser!.uid)
          .limit(50)
          .get();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Forward ${_selectedMessages.length} Message${_selectedMessages.length > 1 ? 's' : ''} To',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (groupsSnapshot.docs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'GROUPS',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...groupsSnapshot.docs.map((groupDoc) {
                        final groupData = groupDoc.data();
                        final groupName =
                            groupData['groupName'] ?? 'Unnamed Group';
                        final participantCount =
                            (groupData['participants'] as List?)?.length ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: const Icon(
                              Icons.group,
                              color: AppColors.onPrimary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            groupName,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '$participantCount member${participantCount != 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(modalContext);
                            await _forwardMessagesTo(
                              groupDoc.id,
                              groupName,
                              isGroup: true,
                            );
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
                    if (usersSnapshot.docs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'CONTACTS',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...usersSnapshot.docs.map((userDoc) {
                        final userData = userDoc.data();
                        final userName = userData['name'] ?? 'Unknown User';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            backgroundImage: userData['photoUrl'] != null
                                ? NetworkImage(userData['photoUrl'])
                                : null,
                            child: userData['photoUrl'] == null
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.onPrimary,
                                    size: 20,
                                  )
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            userData['email'] ?? '',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            Navigator.pop(modalContext);
                            await _forwardMessagesTo(
                              userDoc.id,
                              userName,
                              isGroup: false,
                            );
                          },
                        );
                      }).toList(),
                    ],
                    if (usersSnapshot.docs.isEmpty &&
                        groupsSnapshot.docs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.ink.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No contacts or groups found',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading contacts: $e', isError: true);
      }
    }
  }

  Future<void> _forwardMessagesTo(
    String recipientId,
    String recipientName, {
    required bool isGroup,
  }) async {
    if (currentUser == null) return;

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';

      String chatRoomId;

      if (isGroup) {
        chatRoomId = recipientId;
      } else {
        List<String> ids = [currentUser!.uid, recipientId]..sort();
        chatRoomId = ids.join('_');

        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .get();

        if (!chatDoc.exists) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatRoomId)
              .set({
                'participants': [currentUser!.uid, recipientId],
                'isGroup': false,
                'createdAt': FieldValue.serverTimestamp(),
                'lastMessage': '',
                'lastMessageTimestamp': FieldValue.serverTimestamp(),
                'lastMessageSenderId': currentUser!.uid,
              });
        }
      }

      final selectedList = _selectedMessages.toList();
      final batchSize = 10;
      List<QueryDocumentSnapshot> allMessageDocs = [];

      for (int i = 0; i < selectedList.length; i += batchSize) {
        final batch = selectedList.skip(i).take(batchSize).toList();
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatRoomId)
            .collection('messages')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        allMessageDocs.addAll(messagesSnapshot.docs);
      }

      String lastMessageText = '';
      for (var doc in allMessageDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final forwardedMessageData = {
          'text': data['text'] ?? '',
          'senderId': currentUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'isPinned': false,
          'isStarred': false,
          'isDeleted': false,
          'isEdited': false,
          'reactions': [],
          'isForwarded': true,
          'forwardedFrom':
              widget.otherUser['name'] ??
              (widget.isGroup ? widget.otherUser['groupName'] : 'Someone'),
          'forwardedBy': currentUser!.uid,
          'forwardedByName': currentUserName,
          if (isGroup) 'senderName': currentUserName,
          if (data['imageUrl'] != null) 'imageUrl': data['imageUrl'],
        };

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .add(forwardedMessageData);

        if (lastMessageText.isEmpty) {
          lastMessageText = (data['text'] as String?) ?? '📷 Media';
        }
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .update({
            'lastMessage': lastMessageText,
            'lastMessageTimestamp': FieldValue.serverTimestamp(),
            'lastMessageSenderId': currentUser!.uid,
          });

      if (mounted) {
        final messageCount = _selectedMessages.length;
        _selectedMessages.clear();
        setState(() => _isSelectionMode = false);
        _showSnackBar(
          '${messageCount > 1 ? "$messageCount messages" : "Message"} forwarded to $recipientName',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to forward messages: $e', isError: true);
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        _showSnackBar('Copied to clipboard');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to copy', isError: true);
      }
    }
  }

  void _addReaction(Message message, String emoji) async {
    try {
      final reactions = List<String>.from(message.reactions);

      if (reactions.contains(emoji)) {
        reactions.remove(emoji);
      } else {
        reactions.add(emoji);
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(message.id)
          .update({'reactions': reactions});
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showReactionPicker(Message message) {
    if (!mounted) return;

    const quickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏', '🔥', '👏'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'React to Message',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: quickReactions.map((emoji) {
                  final isSelected = message.reactions.contains(emoji);
                  return InkWell(
                    onTap: () {
                      Navigator.pop(modalContext);
                      _addReaction(message, emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.ink.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePinMessage(String messageId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': !currentStatus});

      if (mounted) {
        _showSnackBar(currentStatus ? 'Message unpinned' : 'Message pinned');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _toggleStarMessage(String messageId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isStarred': !currentStatus});

      if (mounted) {
        _showSnackBar(currentStatus ? 'Message unstarred' : 'Message starred');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  // ✅ --- START: CORRECTED DELETE LOGIC --- ✅

  /// This is the new helper function that updates the parent chat document after a deletion.
  /// This ensures the homepage gets the latest information.
  Future<void> _updateLastMessageAfterDeletion() async {
    if (currentUser == null) return;
    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId);

    // Get the latest message that is still visible to the current user.
    final messagesSnapshot = await chatRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    // Find the first message in the ordered list that is not deleted for the current user.
    final validMessages = messagesSnapshot.docs.where((doc) {
      final data = doc.data();
      final isDeletedForAll = data['isDeleted'] ?? false;
      final deletedForMe =
          (data['deletedFor'] as List<dynamic>?)?.contains(currentUser!.uid) ??
          false;
      return !isDeletedForAll && !deletedForMe;
    }).toList();

    if (validMessages.isNotEmpty) {
      // If there are still messages, update the parent chat with the new latest one.
      final lastDoc = validMessages.first;
      final lastData = lastDoc.data();
      String lastMsgText = lastData['text'] ?? '';
      if (lastMsgText.isEmpty && lastData['imageUrl'] != null) {
        lastMsgText = '📷 Photo';
      }

      await chatRef.update({
        'lastMessage': lastMsgText,
        'lastMessageTimestamp': lastData['timestamp'],
        'lastMessageSenderId': lastData['senderId'],
      });
    } else {
      // No messages left. Clear the last message details to hide it from the homepage.
      await chatRef.update({
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _deleteMessageForMe(String messageId) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedFor': FieldValue.arrayUnion([currentUser!.uid]),
          });

      // After deleting, update the parent chat document. This is the crucial fix.
      await _updateLastMessageAfterDeletion();

      if (mounted) {
        _showSnackBar('Message removed for you');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _deleteMessageForEveryone(String messageId) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
            'isDeleted': true,
            'deletedBy': currentUser!.uid,
            'text': 'This message was deleted',
            'imageUrl': FieldValue.delete(),
          });

      // After deleting, update the parent chat document. This is the crucial fix.
      await _updateLastMessageAfterDeletion();

      if (mounted) {
        _showSnackBar('Message deleted for everyone');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  // ✅ --- END: CORRECTED DELETE LOGIC --- ✅

  void _reportMessage(String messageId) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'messageId': messageId,
        'chatRoomId': widget.chatRoomId,
        'reportedBy': currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnackBar('Message reported successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showEditMessageDialog(Message message) {
    if (!mounted) return;

    final TextEditingController editController = TextEditingController(
      text: message.text,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit Message',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: editController,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          maxLines: null,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Edit your message',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.ink.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                try {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .collection('messages')
                      .doc(message.id)
                      .update({
                        'text': newText,
                        'isEdited': true,
                        'editedTimestamp': FieldValue.serverTimestamp(),
                      });
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    _showSnackBar('Message edited successfully');
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Failed to edit message', isError: true);
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showStarredMessages() {
    if (currentUser == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StarredMessagesPage(
          chatRoomId: widget.chatRoomId,
          currentUserId: currentUser!.uid,
        ),
      ),
    );
  }

  void _showPinnedMessages() {
    if (currentUser == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinnedMessagesPage(
          chatRoomId: widget.chatRoomId,
          currentUserId: currentUser!.uid,
        ),
      ),
    );
  }

  void _showMessageOptions(Message message) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Message Options',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildMenuItem(
                icon: Icons.reply,
                title: 'Reply',
                onTap: () {
                  Navigator.pop(modalContext);
                  _replyToMessage(message);
                },
              ),
              if (message.text.isNotEmpty && !message.isDeleted)
                _buildMenuItem(
                  icon: Icons.copy,
                  title: 'Copy',
                  onTap: () {
                    Navigator.pop(modalContext);
                    _copyToClipboard(message.text);
                  },
                ),
              _buildMenuItem(
                icon: Icons.add_reaction_outlined,
                title: 'React',
                onTap: () {
                  Navigator.pop(modalContext);
                  _showReactionPicker(message);
                },
              ),
              _buildMenuItem(
                icon: Icons.forward,
                title: 'Forward',
                onTap: () {
                  Navigator.pop(modalContext);
                  _selectedMessages.clear();
                  _selectedMessages.add(message.id);
                  setState(() => _isSelectionMode = true);
                  _forwardMessages();
                },
              ),
              _buildMenuItem(
                icon: Icons.select_all,
                title: 'Select Multiple',
                onTap: () {
                  Navigator.pop(modalContext);
                  _toggleMessageSelection(message.id);
                },
              ),

              _buildMenuItem(
                icon: message.isStarred ? Icons.star : Icons.star_outline,
                title: message.isStarred ? 'Unstar' : 'Star',
                onTap: () {
                  Navigator.pop(modalContext);
                  _toggleStarMessage(message.id, message.isStarred);
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildMenuItem(
                icon: Icons.report_outlined,
                title: 'Report',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showReportMessageDialog(message.id);
                },
              ),
              if (message.isSentByMe && !message.isDeleted)
                _buildMenuItem(
                  icon: Icons.edit,
                  title: 'Edit',
                  onTap: () {
                    Navigator.pop(modalContext);
                    _showEditMessageDialog(message);
                  },
                ),
              _buildMenuItem(
                icon: Icons.delete,
                title: 'Delete',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showDeleteOptions(message);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == AppColors.textPrimary ? AppColors.textSecondary : color,
        size: 22,
      ),
      title: Text(title, style: GoogleFonts.inter(color: color, fontSize: 15)),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showReportMessageDialog(String messageId) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Report Message?',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to report this message?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _reportMessage(messageId);
            },
            child: Text('Report', style: GoogleFonts.inter(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showDeleteOptions(Message message) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Delete Message',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 22,
              ),
              title: Text(
                'Delete for Me',
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _deleteMessageForMe(message.id);
              },
            ),
            if (message.isSentByMe)
              ListTile(
                leading: const Icon(
                  Icons.delete_sweep,
                  color: AppColors.danger,
                  size: 22,
                ),
                title: Text(
                  'Delete for Everyone',
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  _showDeleteForEveryoneDialog(message.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteForEveryoneDialog(String messageId) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete for Everyone?',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will remove the message for everyone in the chat.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteMessageForEveryone(messageId);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showContactInfo() {
    if (currentUser == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactInfoPage(
          user: widget.otherUser,
          isGroup: widget.isGroup,
          chatRoomId: widget.chatRoomId,
          currentUserId: currentUser!.uid,
        ),
      ),
    );
  }

  void _showChatOptions() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chat Options',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'View Contact Info',
                onTap: () {
                  Navigator.pop(modalContext);
                  _showContactInfo();
                },
              ),

              _buildMenuItem(
                icon: Icons.star,
                title: 'Starred Messages',
                onTap: () {
                  Navigator.pop(modalContext);
                  _showStarredMessages();
                },
              ),
              _buildMenuItem(
                icon: Icons.search,
                title: 'Search Messages',
                onTap: () {
                  Navigator.pop(modalContext);
                  _toggleSearch();
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              _buildMenuItem(
                icon: Icons.report_outlined,
                title: 'Report ${widget.otherUser['name'] ?? 'User'}',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showReportUserDialog();
                },
              ),

              _buildMenuItem(
                icon: Icons.delete_outline,
                title: 'Delete chat',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showDeleteChatDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportUserDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Report ${widget.otherUser['name'] ?? 'User'}?',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to report this user?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (currentUser == null) return;

              Navigator.pop(dialogContext);
              final otherUserId = widget.otherUser['id'];
              if (otherUserId == null) return;

              try {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reportedUserId': otherUserId,
                  'reportedBy': currentUser!.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  _showSnackBar('User reported successfully');
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Failed to report user', isError: true);
                }
              }
            },
            child: Text('Report', style: GoogleFonts.inter(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Chat?',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete chat history on your device only? The other person will still have the chat.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (currentUser == null) return;

              try {
                final messages = await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .get();

                final batch = FirebaseFirestore.instance.batch();

                for (var doc in messages.docs) {
                  batch.update(doc.reference, {
                    'deletedFor': FieldValue.arrayUnion([currentUser!.uid]),
                  });
                }

                await batch.commit();

                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .update({
                      'deletedFor': FieldValue.arrayUnion([currentUser!.uid]),
                    });

                if (mounted) {
                  _showSnackBar('Chat deleted successfully');
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: ${e.toString()}', isError: true);
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildChatAppBar(),
      body: GestureDetector(
        onTap: () {
          if (_showEmojiPicker) {
            setState(() => _showEmojiPicker = false);
          }
        },
        child: Container(
          color: AppColors.background,
          child: Column(
            children: [
              if (_showSearchBar) _buildSearchBar(),
              if (_isSelectionMode) _buildSelectionBar(),
              Expanded(child: _buildMessagesList()),
              if (_isUploading) _buildUploadingIndicator(),
              if (_replyingTo != null) _buildReplyBar(),
              _ChatInputBar(
                messageController: _messageController,
                onSendPressed: _sendMessage,
                showSendButton: _showSendButton,
                onEmojiPressed: _toggleEmojiPicker,
                showEmojiPicker: _showEmojiPicker,
              ),
              if (_showEmojiPicker) _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _cancelSelection,
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedMessages.length} selected',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.forward, color: AppColors.textPrimary),
            onPressed: _forwardMessages,
            tooltip: 'Forward',
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingTo!.isSentByMe ? 'yourself' : widget.otherUser['name'] ?? 'User'}',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingTo!.text.length > 50
                      ? '${_replyingTo!.text.substring(0, 50)}...'
                      : _replyingTo!.text,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: _cancelReply,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: _toggleSearch,
          ),
          filled: true,
          fillColor: AppColors.surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          'Authentication error',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages',
              style: GoogleFonts.inter(color: AppColors.danger),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppColors.ink.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Say hello! 👋',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 18),
                ),
              ],
            ),
          );
        }

        var messages = snapshot.data!.docs;

        messages = messages.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final deletedFor = data?['deletedFor'];
          if (deletedFor != null && deletedFor is List) {
            return !deletedFor.contains(currentUser!.uid);
          }
          return true;
        }).toList();

        if (_searchQuery.isNotEmpty) {
          messages = messages.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return (data?['text']?.toString() ?? '').toLowerCase().contains(
              _searchQuery,
            );
          }).toList();

          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No messages found',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>?;

            if (data == null) return const SizedBox.shrink();

            final message = Message.fromMap(doc.id, data, currentUser!.uid);

            final bool showDateSeparator =
                index == messages.length - 1 ||
                (index < messages.length - 1 &&
                    _shouldShowDateSeparator(
                      message.timestamp,
                      (messages[index + 1].data()
                          as Map<String, dynamic>?)?['timestamp'],
                    ));

            final bool showNowSeparator =
                index == 0 &&
                DateTime.now().difference(message.timestamp).inMinutes < 1;

            return Column(
              children: [
                if (showNowSeparator)
                  _DateSeparator(date: message.timestamp, isNow: true)
                else if (showDateSeparator)
                  _DateSeparator(date: message.timestamp),
                _MessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  isGroup: widget.isGroup,
                  onLongPress: () {
                    if (_isSelectionMode) {
                      _toggleMessageSelection(message.id);
                    } else {
                      _showMessageOptions(message);
                    }
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleMessageSelection(message.id);
                    } else {
                      _showMessageOptions(message);
                    }
                  },
                  isSelected: _selectedMessages.contains(message.id),
                  isSelectionMode: _isSelectionMode,
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateSeparator(
    DateTime currentDate,
    dynamic previousTimestamp,
  ) {
    if (previousTimestamp == null) return true;

    try {
      final previousDate = (previousTimestamp as Timestamp).toDate();
      return currentDate.day != previousDate.day ||
          currentDate.month != previousDate.month ||
          currentDate.year != previousDate.year;
    } catch (e) {
      return false;
    }
  }

  Widget _buildUploadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Uploading image...',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emojis',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() => _showEmojiPicker = false);
                  },
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: kCommonEmojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => _onEmojiSelected(kCommonEmojis[index]),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      kCommonEmojis[index],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildChatAppBar() {
    return VAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 22),
        onPressed: () => Navigator.pop(context),
        splashRadius: 24,
      ),
      titleSpacing: 0,
      titleWidget: GestureDetector(
        onTap: _showContactInfo,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.onPrimary.withOpacity(0.2),
              backgroundImage: widget.otherUser['photoUrl'] != null
                  ? NetworkImage(widget.otherUser['photoUrl']!)
                  : null,
              child: widget.otherUser['photoUrl'] == null
                  ? Icon(
                      widget.isGroup ? Icons.group : Icons.person,
                      color: AppColors.onPrimary,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser['name']?.toString() ??
                        widget.otherUser['groupName']?.toString() ??
                        'User',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.isGroup)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.otherUser['id'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text(
                            "offline",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onPrimary.withOpacity(0.75),
                            ),
                          );
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final isOnline = data['isOnline'] ?? false;
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF5BE38D)
                                    : const Color(0xFFFF8A8A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOnline ? "Present" : "Absent",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onPrimary.withOpacity(0.85),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Text(
                      "group chat",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onPrimary.withOpacity(0.75),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, size: 22),
          onPressed: _showChatOptions,
          splashRadius: 24,
        ),
      ],
    );
  }
}

// MESSAGE BUBBLE
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isGroup;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isGroup,
    required this.onLongPress,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isSentByMe;

    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                'This message was deleted',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Column(
        children: [
          if (message.isPinned || message.isStarred)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
              child: Row(
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (message.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.push_pin,
                            size: 10,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.isPinned && message.isStarred)
                    const SizedBox(width: 6),
                  if (message.isStarred)
                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                ],
              ),
            ),
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe
                            ? const Radius.circular(18)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isGroup && !isMe && message.senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.senderName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (message.isForwarded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forward,
                                  size: 14,
                                  color: (isMe ? AppColors.onPrimary : AppColors.textPrimary).withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  message.forwardedByName != null
                                      ? 'Forwarded by ${message.forwardedByName}'
                                      : 'Forwarded',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: (isMe ? AppColors.onPrimary : AppColors.textPrimary).withOpacity(0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (message.replyToText != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: (isMe ? AppColors.onPrimary : AppColors.primary)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: isMe
                                      ? AppColors.onPrimary
                                      : AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              message.replyToText!.length > 50
                                  ? '${message.replyToText!.substring(0, 50)}...'
                                  : message.replyToText!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isMe
                                    ? AppColors.onPrimary.withOpacity(0.85)
                                    : AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (message.imageUrl != null)
                          Container(
                            constraints: const BoxConstraints(
                              maxWidth: 250,
                              maxHeight: 300,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                message.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 150,
                                        color: AppColors.ink.withOpacity(0.1),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: AppColors.ink.withOpacity(0.1),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: AppColors.textMuted,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (message.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.text,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: isMe
                                    ? AppColors.onPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        if (message.reactions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isMe ? AppColors.onPrimary : AppColors.ink)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              spacing: 4,
                              children: message.reactions
                                  .map(
                                    (emoji) => Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isEdited) ...[
                              Text(
                                'Edited • ',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: (isMe ? AppColors.onPrimary : AppColors.textPrimary).withOpacity(0.55),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            Text(
                              DateFormat('h:mm a').format(message.timestamp),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: (isMe ? AppColors.onPrimary : AppColors.textPrimary).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// DATE SEPARATOR
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isNow;

  const _DateSeparator({super.key, required this.date, this.isNow = false});

  String _getDisplayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayDate = isNow ? 'Now' : _getDisplayDate(date);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink.withOpacity(0.1)),
        ),
        child: Text(
          displayDate,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// CHAT INPUT BAR
class _ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSendPressed;
  final bool showSendButton;
  final VoidCallback onEmojiPressed;
  final bool showEmojiPicker;

  const _ChatInputBar({
    required this.messageController,
    required this.onSendPressed,
    required this.showSendButton,
    required this.onEmojiPressed,
    required this.showEmojiPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.ink.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: onEmojiPressed,
                      splashRadius: 24,
                    ),
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        maxLines: null,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Message",
                          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onTap: () {
                          if (showEmojiPicker) onEmojiPressed();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: showSendButton
                  ? AppColors.primary
                  : AppColors.border,
              child: IconButton(
                icon: const Icon(Icons.send, color: AppColors.onPrimary, size: 20),
                onPressed: showSendButton ? onSendPressed : null,
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// STARRED MESSAGES PAGE
class StarredMessagesPage extends StatelessWidget {
  final String chatRoomId;
  final String currentUserId;

  const StarredMessagesPage({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VAppBar(title: 'Starred Messages'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .where('isStarred', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading starred messages',
                    style: GoogleFonts.inter(color: AppColors.danger, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_outline,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No starred messages',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Star important messages to find them easily',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>?;

              if (data == null) return const SizedBox.shrink();

              final message = Message.fromMap(doc.id, data, currentUserId);

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.star,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  title: Text(
                    message.text.isNotEmpty
                        ? message.text
                        : message.imageUrl != null
                        ? '📷 Photo'
                        : 'Message',
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(message.timestamp),
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// PINNED MESSAGES PAGE
class PinnedMessagesPage extends StatelessWidget {
  final String chatRoomId;
  final String currentUserId;

  const PinnedMessagesPage({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VAppBar(title: 'Pinned Messages'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .where('isPinned', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading pinned messages',
                    style: GoogleFonts.inter(color: AppColors.danger, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.push_pin_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pinned messages',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pin important messages to find them easily',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>?;

              if (data == null) return const SizedBox.shrink();

              final message = Message.fromMap(doc.id, data, currentUserId);

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.push_pin,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  title: Text(
                    message.text.isNotEmpty
                        ? message.text
                        : message.imageUrl != null
                        ? '📷 Photo'
                        : 'Message',
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(message.timestamp),
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// CONTACT INFO PAGE
class ContactInfoPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isGroup;
  final String chatRoomId;
  final String currentUserId;

  const ContactInfoPage({
    super.key,
    required this.user,
    required this.isGroup,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editGroupAbout(String currentAbout) async {
    final TextEditingController aboutController = TextEditingController(
      text: currentAbout,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit About',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: aboutController,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          maxLines: 3,
          maxLength: 200,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter group description',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.ink.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newAbout = aboutController.text.trim();
              if (newAbout.isNotEmpty && newAbout != currentAbout) {
                try {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .update({'groupDescription': newAbout});

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('About updated successfully'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: AppColors.danger,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMemberDialog(List<String> currentMembers) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: widget.currentUserId)
          .get();

      final availableUsers = usersSnapshot.docs
          .where((doc) => !currentMembers.contains(doc.id))
          .toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) => StatefulBuilder(
          builder: (context, setModalState) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add Members',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Expanded(
                  child: availableUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.ink.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users to add',
                                style: GoogleFonts.inter(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: availableUsers.length,
                          itemBuilder: (context, index) {
                            final userDoc = availableUsers[index];
                            final userData = userDoc.data();
                            final userName = userData['name'] ?? 'Unknown';
                            final userEmail = userData['email'] ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                backgroundImage: userData['photoUrl'] != null
                                    ? NetworkImage(userData['photoUrl'])
                                    : null,
                                child: userData['photoUrl'] == null
                                    ? const Icon(
                                        Icons.person,
                                        color: AppColors.onPrimary,
                                        size: 20,
                                      )
                                    : null,
                              ),
                              title: Text(
                                userName,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                userEmail,
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                Navigator.pop(modalContext);
                                await _addMemberToGroup(userDoc.id, userData);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _addMemberToGroup(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .update({
            'participants': FieldValue.arrayUnion([userId]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${userData['name'] ?? 'User'} added to group'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add member: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VAppBar(title: 'Contact Info'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary,
              backgroundImage: widget.user['photoUrl'] != null
                  ? NetworkImage(widget.user['photoUrl'])
                  : null,
              child: widget.user['photoUrl'] == null
                  ? Icon(
                      widget.isGroup ? Icons.group : Icons.person,
                      size: 50,
                      color: AppColors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              widget.user['name']?.toString() ??
                  widget.user['groupName']?.toString() ??
                  'Unknown',
              style: GoogleFonts.inter(
                fontSize: 24,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user['email']?.toString() ??
                  widget.user['phone']?.toString() ??
                  'No contact info',
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            const Divider(color: AppColors.border),

            if (!widget.isGroup) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('isGroup', isEqualTo: true)
                      .where('participants', arrayContains: widget.user['id'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return ListTile(
                        leading: const Icon(
                          Icons.group,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        title: Text(
                          'Groups',
                          style: GoogleFonts.inter(color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          'Loading...',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                      );
                    }

                    final groups = snapshot.data!.docs;
                    final groupCount = groups.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.group,
                                  color: AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Common Groups',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$groupCount',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (groupCount == 0)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'No common groups',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupCount,
                            itemBuilder: (context, index) {
                              final groupData =
                                  groups[index].data() as Map<String, dynamic>;
                              final groupName =
                                  groupData['groupName'] ?? 'Unnamed Group';
                              final participantCount =
                                  (groupData['participants'] as List?)
                                      ?.length ??
                                  0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: AppColors.ink.withOpacity(0.1),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(
                                      Icons.group,
                                      color: AppColors.onPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    groupName,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$participantCount member${participantCount != 1 ? 's' : ''}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.textMuted,
                                    size: 14,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(color: AppColors.border),
              ListTile(
                leading: const Icon(
                  Icons.phone,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                title: Text(
                  'Phone',
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  widget.user['phone']?.toString() ?? 'Not available',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.email,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                title: Text(
                  'Email',
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  widget.user['email']?.toString() ?? 'Not available',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ),
            ],

            if (widget.isGroup) ...[
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      title: Text(
                        'About',
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        'Loading...',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final groupDescription =
                      data?['groupDescription'] ??
                      'Hey there! This is a group.';
                  final createdBy = data?['createdBy'] as String? ?? '';
                  final isAdmin = createdBy == widget.currentUserId;

                  return ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    title: Text(
                      'About',
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      groupDescription,
                      style: GoogleFonts.inter(color: AppColors.textMuted),
                    ),
                    trailing: isAdmin
                        ? IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => _editGroupAbout(groupDescription),
                            splashRadius: 24,
                          )
                        : null,
                  );
                },
              ),
              const Divider(color: AppColors.border),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) return const SizedBox.shrink();

                  final participants =
                      (data['participants'] as List<dynamic>?)
                          ?.cast<String>() ??
                      [];
                  final createdBy = data['createdBy'] as String? ?? '';
                  final createdAt = data['createdAt'] as Timestamp?;
                  final isAdmin = createdBy == widget.currentUserId;

                  return Column(
                    children: [
                      if (createdBy.isNotEmpty)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(createdBy)
                              .get(),
                          builder: (context, userSnapshot) {
                            String creatorName = 'Unknown';

                            if (userSnapshot.connectionState ==
                                ConnectionState.done) {
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                final userData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>?;
                                creatorName = userData?['name'] ?? 'Unknown';
                              } else if (createdBy == widget.currentUserId) {
                                creatorName = 'You';
                              }
                            }

                            return ListTile(
                              leading: const Icon(
                                Icons.person_outline,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                              title: Text(
                                'Created By',
                                style: GoogleFonts.inter(color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                creatorName,
                                style: GoogleFonts.inter(color: AppColors.textMuted),
                              ),
                            );
                          },
                        ),
                      if (createdAt != null)
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          title: Text(
                            'Created On',
                            style: GoogleFonts.inter(color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            DateFormat('MMMM d, y').format(createdAt.toDate()),
                            style: GoogleFonts.inter(color: AppColors.textMuted),
                          ),
                        ),
                      const Divider(color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Members (${participants.length})',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (participants.length > 5)
                              IconButton(
                                icon: Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.search
                                      : Icons.close,
                                  color: AppColors.textSecondary,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_searchQuery.isEmpty) {
                                      _searchQuery = ' ';
                                    } else {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    }
                                  });
                                },
                                splashRadius: 24,
                              ),
                          ],
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(color: AppColors.textPrimary),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.textMuted,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceAlt,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (value) {
                              setState(
                                () => _searchQuery = value.toLowerCase(),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participantId = participants[index];
                          final isCurrentUser =
                              participantId == widget.currentUserId;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(participantId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                  title: Text(
                                    'Loading...',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                );
                              }

                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final userData =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>?;
                              if (userData == null) {
                                return const SizedBox.shrink();
                              }

                              final name = userData['name'] ?? 'Unknown';
                              final email = userData['email'] ?? '';

                              if (_searchQuery.isNotEmpty &&
                                  _searchQuery.trim().isNotEmpty) {
                                final query = _searchQuery.toLowerCase();
                                if (!name.toLowerCase().contains(query) &&
                                    !email.toLowerCase().contains(query)) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  backgroundImage: userData['photoUrl'] != null
                                      ? NetworkImage(userData['photoUrl'])
                                      : null,
                                  child: userData['photoUrl'] == null
                                      ? const Icon(
                                          Icons.person,
                                          color: AppColors.onPrimary,
                                          size: 20,
                                        )
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isCurrentUser ? 'You' : name,
                                        style: GoogleFonts.inter(
                                          color: AppColors.textPrimary,
                                          fontWeight: isCurrentUser
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (participantId == createdBy)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        child: Text(
                                          'Admin',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  email,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isAdmin && !isCurrentUser
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: AppColors.textSecondary,
                                        ),
                                        color: AppColors.surface,
                                        onSelected: (value) async {
                                          if (value == 'remove') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (dialogContext) =>
                                                  AlertDialog(
                                                    backgroundColor:
                                                        AppColors.surface,
                                                    title: Text(
                                                      'Remove Member?',
                                                      style: GoogleFonts.inter(
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to remove $name from this group?',
                                                      style: GoogleFonts.inter(
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                              false,
                                                            ),
                                                        child: Text(
                                                          'Cancel',
                                                          style:
                                                              GoogleFonts.inter(
                                                                color: AppColors.textSecondary,
                                                              ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                              true,
                                                            ),
                                                        child: Text(
                                                          'Remove',
                                                          style:
                                                              GoogleFonts.inter(
                                                                color:
                                                                    AppColors.danger,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            if (confirm == true) {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('chats')
                                                    .doc(widget.chatRoomId)
                                                    .update({
                                                      'participants':
                                                          FieldValue.arrayRemove(
                                                            [participantId],
                                                          ),
                                                    });

                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '$name removed from group',
                                                      ),
                                                      backgroundColor:
                                                          AppColors.success,
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to remove member: $e',
                                                      ),
                                                      backgroundColor:
                                                          AppColors.danger,
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'remove',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.person_remove,
                                                  color: AppColors.danger,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Remove from group',
                                                  style: GoogleFonts.inter(
                                                    color: AppColors.danger,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showAddMemberDialog(participants);
                            },
                            icon: const Icon(Icons.person_add),
                            label: Text(
                              'Add Members',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (!isAdmin)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: Text(
                                    'Leave Group?',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to leave this group?',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(
                                        'Leave',
                                        style: GoogleFonts.inter(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(widget.chatRoomId)
                                      .update({
                                        'participants': FieldValue.arrayRemove([
                                          widget.currentUserId,
                                        ]),
                                      });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Left group successfully',
                                        ),
                                        backgroundColor: AppColors.success,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to leave: $e'),
                                        backgroundColor: AppColors.danger,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.exit_to_app),
                            label: Text(
                              'Leave Group',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: AppColors.onPrimary,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
