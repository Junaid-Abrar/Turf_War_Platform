import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key, 
    required this.receiverId, 
    required this.receiverName
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort(); // Ensure unique ID regardless of who starts
    return ids.join('_');
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser == null) return;

    final chatId = _getChatId(currentUser.id, widget.receiverId);
    final messageText = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser.id,
      'senderName': currentUser.name,
      'receiverId': widget.receiverId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the main chat doc for listing purposes
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': messageText,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'users': [currentUser.id, widget.receiverId],
      'userName': currentUser.name,
      'ownerName': widget.receiverName,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).user;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Please login')));

    final chatId = _getChatId(currentUser.id, widget.receiverId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                          ),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
