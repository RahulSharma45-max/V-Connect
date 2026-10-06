import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A one-to-one chat room that is ready to open in `ChatPage`.
class DirectChat {
  final String chatRoomId;

  /// The other user's data with both `id` and `uid` set, as `ChatPage` expects.
  final Map<String, dynamic> otherUser;

  const DirectChat(this.chatRoomId, this.otherUser);
}

/// Finds or creates the DM room between the signed-in user and [userData].
///
/// Returns null when nobody is signed in or [userData] has no usable id
/// (or is the signed-in user). Firestore errors are rethrown.
Future<DirectChat?> ensureDirectChat(Map<String, dynamic> userData) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return null;

  final String? rawOtherId =
      (userData['id'] != null && userData['id'].toString().isNotEmpty)
      ? userData['id'].toString()
      : ((userData['uid'] != null && userData['uid'].toString().isNotEmpty)
            ? userData['uid'].toString()
            : null);

  if (rawOtherId == null || rawOtherId == currentUser.uid) return null;

  final Map<String, dynamic> preparedOtherUser = Map<String, dynamic>.from(
    userData,
  );
  preparedOtherUser['id'] = rawOtherId;
  preparedOtherUser['uid'] = rawOtherId;

  List<String> ids = [currentUser.uid, rawOtherId]..sort();
  String chatRoomId = ids.join('_');

  final chatRef = FirebaseFirestore.instance
      .collection('chats')
      .doc(chatRoomId);
  final doc = await chatRef.get();
  if (doc.exists) {
    await chatRef.update({'unreadCount.${currentUser.uid}': 0});
  } else {
    await chatRef.set({
      'participants': [currentUser.uid, rawOtherId],
      'isGroup': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Chat started',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUser.uid,
      'unreadCount': {currentUser.uid: 0, rawOtherId: 0},
      'archivedBy': {currentUser.uid: false, rawOtherId: false},
    });
  }

  return DirectChat(chatRoomId, preparedOtherUser);
}
