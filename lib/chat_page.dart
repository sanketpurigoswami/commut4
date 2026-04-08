import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatPage extends StatefulWidget {
  final String rideId;
  final int groupNumber;

  const ChatPage({
    super.key,
    required this.rideId,
    required this.groupNumber,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _msgSubscription;

  late final String _chatroomId;
  late final DatabaseReference _chatRef;
  late final String _currentUid;
  late final String _displayName;

  @override
  void initState() {
    super.initState();
    final user   = FirebaseAuth.instance.currentUser!;
    _currentUid  = user.uid;
    _displayName = (user.displayName ?? 'Unknown').split(' ').first;
    _chatroomId  = '${widget.rideId}_g${widget.groupNumber}';
    print('=== CHATROOM ID: $_chatroomId ===');
    _chatRef     = FirebaseDatabase.instance.ref('chats/$_chatroomId/messages');
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _msgSubscription?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToMessages() {
    _msgSubscription = _chatRef
        .orderByChild('timestamp')
        .onChildAdded
        .listen((DatabaseEvent event) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _messages.add({
              'key':        event.snapshot.key,
              'uid':        data['uid'] as String,
              'text':       data['text'] as String,
              'timestamp':  data['timestamp'] as int? ?? 0,
              'senderName': data['senderName'] as String? ?? 'Unknown',
            });
          });
          _scrollToBottom();
        });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    try {
      print('=== SENDING MESSAGE ===');
      print('Chatroom ID: $_chatroomId');
      print('RTDB ref path: ${_chatRef.path}');
      print('UID: $_currentUid');
      print('Text: $text');

      await _chatRef.push().set({
        'uid':        _currentUid,
        'senderName': _displayName,
        'text':       text,
        'timestamp':  ServerValue.timestamp,
      });

      print('=== MESSAGE SENT SUCCESSFULLY ===');
    } catch (e, stack) {
      print('=== SEND FAILED ===');
      print('Error: $e');
      print('Stack: $stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563eb),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Chat',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              'Group ${widget.groupNumber}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet.\nSay hello to your group! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg   = _messages[index];
                        final isMe  = msg['uid'] == _currentUid;
                        return _buildBubble(msg['text'], isMe, msg['timestamp'], msg['senderName'] ?? 'Unknown');
                      },
                    ),
            ),
          ),

          // Input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563eb),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe, int timestamp, String senderName) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(
                senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563eb),
                ),
              ),
            ),
          Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.70,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2563eb) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1a1a1a),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe
                    ? Colors.white.withOpacity(0.65)
                    : Colors.grey[400],
                fontSize: 10,
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