import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        await _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName =
        (widget.tappedUser['firstName'] ?? 'Unknown').toString();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: CustomText(
              text: tappedUserName,
              fontSize: 25.sp,
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading messages: ${snapshot.error}'),
                      );
                    }

                    final List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];
                    // Hide optimistic messages until the send delay completes.
                    final visibleDocs = docs.where((d) {
                      if (!_isSending || _sendingStartedAt == null) return true;
                      final data = d.data() as Map<String, dynamic>;
                      final senderId = (data['senderId'] ?? '').toString();
                      final ts = data['timestamp'];
                      if (senderId != currentUserId) return true;
                      if (ts is Timestamp) {
                        return ts.compareTo(_sendingStartedAt!) < 0;
                      }
                      return true;
                    }).toList();

                    if (visibleDocs.isEmpty) {
                      return const Center(child: Text('No messages yet :)'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: visibleDocs.length,
                      itemBuilder: (context, index) {
                        final data =
                            visibleDocs[index].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final isLatestMine = isMe && index == 0;

                        // ENHANCEMENT 3: Fade and slide each message into the list.
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 280),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // ENHANCEMENT 3: chat_bubbles separates sender and receiver.
                              BubbleSpecialOne(
                                text: msgText.isNotEmpty ? msgText : '(empty)',
                                isSender: isMe,
                                color: isMe
                                    ? const Color(0xFF1B97F3)
                                    : const Color(0xFFE8E8EE),
                                tail: true,
                                textStyle: TextStyle(
                                  fontSize: 15.sp,
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              if (isLatestMine)
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: isMe ? 22 : 0,
                                    left: isMe ? 0 : 22,
                                    bottom: 4,
                                  ),
                                  child: _isSending
                                      ? CustomText(
                                          text: 'Sending...',
                                          fontSize: 11.sp,
                                          color: Colors.grey,
                                        )
                                      : Icon(
                                          Icons.done_all,
                                          size: 16.sp,
                                          color: const Color(0xFF1B97F3),
                                        ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) =>
                              _isSending ? null : _send(currentUserId, tappedUserId),
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            hintStyle: TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () => _send(currentUserId, tappedUserId),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
