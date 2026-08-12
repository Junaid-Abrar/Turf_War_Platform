import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
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
  bool _isSending = false;

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
    if (text.isEmpty || _isSending) return;

    final UserModel? currentUser = context.read<UserProvider>().user;
    if (currentUser == null) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // Cleared optimistically so the field is ready for the next message; the
    // text is restored below if the write fails.
    _messageController.clear();
    setState(() => _isSending = true);

    final String chatId = _chatIdFor(currentUser.id, widget.receiverId);
    final DocumentReference<Map<String, dynamic>> chatDoc =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    try {
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
    } on FirebaseException catch (e) {
      if (!mounted) return;
      // Putting the text back matters: losing a typed message to a dropped
      // connection is the worst outcome here.
      _messageController.text = text;
      messenger.showSnackBar(
        SnackBar(content: Text('Message not sent: ${e.message ?? e.code}')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserModel? currentUser = context.watch<UserProvider>().user;

    if (currentUser == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Sign in to chat',
          message: 'Messages are tied to your account.',
        ),
      );
    }

    final String chatId = _chatIdFor(currentUser.id, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                widget.receiverName.isEmpty
                    ? '?'
                    : widget.receiverName[0].toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                widget.receiverName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
                  return const ErrorState(
                    message: 'Messages could not be loaded. Check your '
                        'connection and try again.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                    messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Say hello',
                    message: 'Ask ${widget.receiverName} about the pitch, '
                        'kit, or parking.',
                  );
                }

                return ListView.builder(
                  // Newest at the bottom, and the list starts scrolled there.
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> message =
                        messages[index].data();
                    final Timestamp? timestamp =
                        message['timestamp'] as Timestamp?;

                    // The list is reversed, so the "next" entry is the older
                    // one — a date separator goes above a message whose
                    // predecessor fell on a different day.
                    final Timestamp? previousTimestamp =
                        index + 1 < messages.length
                            ? messages[index + 1].data()['timestamp']
                                as Timestamp?
                            : null;

                    return Column(
                      children: <Widget>[
                        if (_needsDateSeparator(timestamp, previousTimestamp))
                          _DateSeparator(date: timestamp!.toDate()),
                        _MessageBubble(
                          text: message['text'] as String? ?? '',
                          isMine: message['senderId'] == currentUser.id,
                          timestamp: timestamp,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  /// True when [current] starts a new calendar day relative to [previous].
  ///
  /// A just-sent message has a null server timestamp until Firestore resolves
  /// it, so it never triggers a separator — it would otherwise flash one in and
  /// out as the write settles.
  bool _needsDateSeparator(Timestamp? current, Timestamp? previous) {
    if (current == null) return false;
    if (previous == null) return true;
    return !DateUtils.isSameDay(current.toDate(), previous.toDate());
  }
}

/// A centred "Today" / "12 Aug" divider between days.
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();

    final String label = DateUtils.isSameDay(date, now)
        ? 'Today'
        : DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))
            ? 'Yesterday'
            : DateFormat('d MMM yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.pillAll,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color background =
        isMine ? colors.primary : colors.surfaceContainerHigh;
    final Color foreground = isMine ? colors.onPrimary : colors.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          // The corner nearest the sender is squared off, which is what makes
          // a run of bubbles read as coming from one side.
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMine ? AppRadius.lg : AppSpacing.xs),
            bottomRight: Radius.circular(isMine ? AppSpacing.xs : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            AppSpacing.gapXxs,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  // A null timestamp means the write has not reached the server
                  // yet.
                  timestamp == null
                      ? 'Sending…'
                      : DateFormat.Hm().format(timestamp!.toDate()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.75),
                    fontSize: 10,
                  ),
                ),
                if (isMine) ...<Widget>[
                  AppSpacing.hGapXs,
                  Icon(
                    timestamp == null ? Icons.schedule : Icons.done_all,
                    size: 12,
                    color: foreground.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The message input row.
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  // Grows with a long message instead of scrolling a single
                  // line, up to a cap so the keyboard is never squeezed out.
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Message…',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              IconButton.filled(
                onPressed: isSending ? null : onSend,
                tooltip: 'Send',
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
