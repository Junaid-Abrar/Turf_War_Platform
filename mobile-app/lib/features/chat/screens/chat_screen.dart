import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../../auth/providers/user_provider.dart';

/// Direct message thread between a user and a venue owner, backed by Firestore.
class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Deterministic thread id: sorting the two user ids means both participants
  /// derive the same document regardless of who opened the chat.
  String _chatIdFor(String userId, String otherId) {
    final List<String> ids = <String>[userId, otherId]..sort();
    return ids.join('_');
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    final UserModel? currentUser = context.read<UserProvider>().user;
    if (currentUser == null) return;

    _messageController.clear();
    final String chatId = _chatIdFor(currentUser.id, widget.receiverId);
    final DocumentReference<Map<String, dynamic>> chatDoc =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatDoc.collection('messages').add(<String, dynamic>{
      'senderId': currentUser.id,
      'senderName': currentUser.name,
      'receiverId': widget.receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Denormalised summary so a future inbox can list threads without reading
    // every message subcollection.
    await chatDoc.set(<String, dynamic>{
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'users': <String>[currentUser.id, widget.receiverId],
      'userName': currentUser.name,
      'ownerName': widget.receiverName,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserModel? currentUser = context.watch<UserProvider>().user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to chat.')),
      );
    }

    final String chatId = _chatIdFor(currentUser.id, widget.receiverId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load messages.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                    messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello 👋',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> message = messages[index].data();
                    return _MessageBubble(
                      text: message['text'] as String? ?? '',
                      isMine: message['senderId'] == currentUser.id,
                      timestamp: message['timestamp'] as Timestamp?,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: theme.colorScheme.primary,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final Timestamp? timestamp;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMine ? Radius.zero : const Radius.circular(20),
            bottomLeft: isMine ? const Radius.circular(20) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              text,
              style: TextStyle(
                color: isMine ? colors.onPrimary : colors.onSurface,
              ),
            ),
            if (timestamp != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                _formatTime(timestamp!.toDate()),
                style: TextStyle(
                  fontSize: 10,
                  color: (isMine ? colors.onPrimary : colors.onSurface)
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
